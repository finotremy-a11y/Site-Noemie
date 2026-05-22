module Payments
  class HandleStripeWebhook
    def initialize(event:)
      @event = event
    end

    def call
      return { ignored: true, reason: "already_processed", event_type: event.type } if already_processed?

      case event.type
      when "checkout.session.completed"
        handle_checkout_completed(event.data.object)
      when "checkout.session.async_payment_failed"
        handle_payment_failed(event.data.object)
      else
        { ignored: true, event_type: event.type }
      end
    end

    private

    attr_reader :event

    def already_processed?
      PaymentEvent.exists?(provider_event_id: event.id)
    end

    def handle_checkout_completed(session)
      order = find_order(session)
      return { ignored: true, reason: "order_not_found", event_type: event.type } unless order

      payment = upsert_payment!(order: order, session: session, status: "pending")

      Order.transaction do
        order.update!(payment_status: "pending")
        order.update!(status: "pending_validation") if order.status == "pending_payment"

        PaymentEvent.create!(
          payment: payment,
          provider_event_id: event.id,
          event_type: event.type,
          payload: event.to_hash,
          occurred_at: Time.zone.at(event.created)
        )
      end

      # Queue email notifications asynchronously
      Notifications::SendOrderConfirmationEmailJob.perform_later(order.id)
      Notifications::SendOrderStatusUpdateEmailJob.perform_later(order.id, order.status)

      processed_payload(order, session, payment.status)
    end

    def handle_payment_failed(session)
      order = find_order(session)
      return { ignored: true, reason: "order_not_found", event_type: event.type } unless order

      payment = upsert_payment!(order: order, session: session, status: "failed")

      Order.transaction do
        order.update!(payment_status: "failed")

        PaymentEvent.create!(
          payment: payment,
          provider_event_id: event.id,
          event_type: event.type,
          payload: event.to_hash,
          occurred_at: Time.zone.at(event.created)
        )
      end

      # Log payment failure to Sentry for monitoring
      if defined?(Sentry)
        Sentry.capture_message(
          "Payment failed for order #{order.order_number}",
          level: :warning,
          extra: {
            order_id: order.id,
            session_id: session.id,
            amount_cents: session.amount_total
          }
        )
      end

      processed_payload(order, session, payment.status)
    end

    def find_order(session)
      order_id = session.metadata["order_id"].presence || session.client_reference_id
      Order.find_by(id: order_id)
    end

    def upsert_payment!(order:, session:, status:)
      provider_payment_id = session.respond_to?(:payment_intent) ? session.payment_intent.to_s : session.id
      provider_payment_id = session.id if provider_payment_id.blank?

      payment = order.payments.find_or_initialize_by(provider: "stripe", provider_payment_id: provider_payment_id)
      payment.status = status
      payment.amount_cents = session.amount_total.to_i if session.respond_to?(:amount_total)
      payment.currency = (session.currency || "eur").upcase
      payment.paid_at = Time.current if status == "paid"
      payment.save!
      payment
    end

    def processed_payload(order, session, payment_status)
      {
        ignored: false,
        event_type: event.type,
        order_id: order.id,
        checkout_session_id: session.id,
        payment_status: payment_status
      }
    end
  end
end
