module Api
  module V1
    class StripeWebhooksController < BaseController
      def create
        payload = request.raw_post
        signature = request.headers["Stripe-Signature"]

        event = Stripe::Webhook.construct_event(
          payload,
          signature,
          ENV.fetch("STRIPE_WEBHOOK_SECRET")
        )

        result = Payments::HandleStripeWebhook.new(event: event).call

        render json: { received: true, processed: result }, status: :ok
      rescue JSON::ParserError, Stripe::SignatureVerificationError => error
        render_error(
          code: "invalid_webhook",
          message: "Webhook Stripe invalide.",
          details: { reason: error.message },
          status: :bad_request
        )
      end
    end
  end
end
