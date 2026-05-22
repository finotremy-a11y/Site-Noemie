module Payments
  class CancelAuthorization
    class CancelError < StandardError
      attr_reader :details

      def initialize(details)
        @details = details
        super("Cancel authorization failed")
      end
    end

    def initialize(order:)
      @order = order
    end

    def call
      payment = find_pending_payment
      return nil unless payment

      payment_intent_id = payment.provider_payment_id.to_s
      if payment_intent_id.blank?
        raise CancelError, { payment: "missing_payment_intent_id" }
      end

      Stripe::PaymentIntent.cancel(payment_intent_id)

      Payment.transaction do
        payment.update!(status: "failed")
        order.update!(payment_status: "failed")
      end

      payment
    rescue Stripe::StripeError => error
      raise CancelError, { stripe: error.message }
    end

    private

    attr_reader :order

    def find_pending_payment
      order.payments.where(provider: "stripe").order(created_at: :desc).find_by(status: "pending")
    end
  end
end
