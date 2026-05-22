module Payments
  class CreateCheckoutSession
    class ValidationError < StandardError
      attr_reader :details

      def initialize(details)
        @details = details
        super("Invalid checkout payload")
      end
    end

    def initialize(payload:, idempotency_key: nil)
      @payload = payload
      @idempotency_key = idempotency_key
    end

    def call
      validate_payload!

      order = Order.find_by(id: payload.fetch("order_id"))
      raise ValidationError, { order_id: "not_found" } unless order

      validate_order!(order)

      existing_payment = find_existing_idempotent_payment(order)
      return build_existing_session_response(order, existing_payment) if existing_payment

      currency = checkout_currency_for(order)

      session = Stripe::Checkout::Session.create({
        mode: "payment",
        payment_intent_data: {
          capture_method: "manual"
        },
        success_url: payload.fetch("success_url"),
        cancel_url: payload.fetch("cancel_url"),
        customer_email: payload["customer_email"].presence || order.customer_email,
        client_reference_id: payload.fetch("order_id"),
        line_items: normalized_line_items(order, currency),
        metadata: {
          order_id: payload.fetch("order_id")
        }
      }, stripe_request_options)

      payment = create_or_find_payment!(order: order, session: session, currency: currency)

      {
        payment_id: payment.id,
        checkout_session_id: session.id,
        checkout_url: session.url,
        order_id: payload.fetch("order_id")
      }
    end

    private

    attr_reader :payload, :idempotency_key

    def validate_payload!
      details = {}
      details[:order_id] = "required" if payload["order_id"].blank?
      details[:success_url] = "required" if payload["success_url"].blank?
      details[:cancel_url] = "required" if payload["cancel_url"].blank?

      raise ValidationError, details if details.any?
    end

    def validate_order!(order)
      details = {}
      details[:order] = "must be pending_payment" unless order.status == "pending_payment"
      details[:payment_status] = "must be pending or failed" unless %w[pending failed].include?(order.payment_status)
      details[:order_items] = "must contain at least one item" if order.order_items.empty?
      details[:total_cents] = "must be greater than zero" if order.total_cents.to_i <= 0
      details[:currency] = "order items must use a single currency" unless single_currency_order?(order)

      raise ValidationError, details if details.any?
    end

    def normalized_line_items(order, currency)
      order.order_items.map do |item|
        {
          quantity: item.quantity,
          price_data: {
            currency: currency.downcase,
            unit_amount: item.unit_price_cents,
            product_data: {
              name: item.name
            }
          }
        }
      end
    end

    def single_currency_order?(order)
      item_currencies = order.order_items.filter_map { |item| item.product&.currency&.upcase }.uniq
      item_currencies.size <= 1
    end

    def checkout_currency_for(order)
      order.order_items.filter_map { |item| item.product&.currency&.upcase }.first || "EUR"
    end

    def create_or_find_payment!(order:, session:, currency:)
      return create_payment!(order: order, session: session, currency: currency) if idempotency_key.blank?

      payment = Payment.find_or_initialize_by(provider: "stripe", idempotency_key: idempotency_key)
      if payment.persisted? && payment.order_id != order.id
        raise ValidationError, { idempotency_key: "already_used_for_another_order" }
      end

      if payment.persisted? && payment.provider_payment_id.present? && payment.provider_payment_id != session.id
        raise ValidationError, { idempotency_key: "already_used_for_another_checkout_session" }
      end

      payment.order ||= order
      payment.provider_payment_id ||= session.id
      payment.status = "pending"
      payment.amount_cents = order.total_cents
      payment.currency = currency
      payment.save!
      payment
    end

    def find_existing_idempotent_payment(order)
      return nil if idempotency_key.blank?

      payment = Payment.find_by(provider: "stripe", idempotency_key: idempotency_key)
      return nil unless payment
      raise ValidationError, { idempotency_key: "already_used_for_another_order" } if payment.order_id != order.id
      return nil if payment.provider_payment_id.blank?

      payment
    end

    def build_existing_session_response(order, payment)
      session = Stripe::Checkout::Session.retrieve(payment.provider_payment_id)

      {
        payment_id: payment.id,
        checkout_session_id: payment.provider_payment_id,
        checkout_url: session.url,
        order_id: order.id
      }
    end

    def create_payment!(order:, session:, currency:)
      Payment.create!(
        order: order,
        provider: "stripe",
        provider_payment_id: session.id,
        status: "pending",
        amount_cents: order.total_cents,
        currency: currency,
        idempotency_key: idempotency_key
      )
    end

    def stripe_request_options
      return {} if idempotency_key.blank?

      { idempotency_key: idempotency_key }
    end
  end
end
