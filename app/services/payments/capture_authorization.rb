module Payments
  class CaptureAuthorization
    class CaptureError < StandardError
      attr_reader :details

      def initialize(details)
        @details = details
        super("Capture authorization failed")
      end
    end

    def initialize(order:)
      @order = order
    end

    def call
      payment = find_pending_payment!
      payment_intent_id = payment.provider_payment_id.to_s

      if payment_intent_id.blank?
        raise CaptureError, { payment: "missing_payment_intent_id" }
      end

      Stripe::PaymentIntent.capture(payment_intent_id)

      Payment.transaction do
        payment.update!(status: "paid", paid_at: Time.current)
        order.update!(payment_status: "paid")
      end

      payment
    rescue Stripe::StripeError => error
      raise CaptureError, { stripe: error.message }
    end

    private

    attr_reader :order

    def find_pending_payment!
      payment = order.payments.where(provider: "stripe").order(created_at: :desc).find_by(status: "pending")
      return payment if payment

      raise CaptureError, { payment: "pending_authorization_not_found" }
    end
  end
end
