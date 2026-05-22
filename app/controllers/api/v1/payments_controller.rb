module Api
  module V1
    class PaymentsController < BaseController
      IDEMPOTENCY_TTL = 30.minutes

      def create_session
        result = create_checkout_session!(payload: create_session_params.to_h)
        render json: result, status: :created
      rescue Payments::CreateCheckoutSession::ValidationError => error
        render_error(
          code: "validation_error",
          message: "Parametres invalides.",
          details: error.details,
          status: :unprocessable_entity
        )
      end

      def retry
        payload = retry_session_params.to_h.merge("order_id" => params[:order_id])
        result = create_checkout_session!(payload: payload)
        render json: result, status: :created
      rescue Payments::CreateCheckoutSession::ValidationError => error
        render_error(
          code: "validation_error",
          message: "Parametres invalides.",
          details: error.details,
          status: :unprocessable_entity
        )
      end

      private

      def create_checkout_session!(payload:)
        idempotency_key = request.headers["Idempotency-Key"].presence
        if idempotency_key
          cached_response = Rails.cache.read(cache_key_for(idempotency_key))
          return extract_cached_result!(cached_response, payload) if cached_response
        end

        result = Payments::CreateCheckoutSession.new(payload: payload, idempotency_key: idempotency_key).call

        if idempotency_key
          Rails.cache.write(
            cache_key_for(idempotency_key),
            {
              "fingerprint" => payload_fingerprint(payload),
              "result" => result
            },
            expires_in: IDEMPOTENCY_TTL
          )
        end

        result
      end

      def cache_key_for(idempotency_key)
        "idem:payments:create_session:#{idempotency_key}"
      end

      def extract_cached_result!(cached_response, payload)
        return cached_response unless cached_response.is_a?(Hash)
        return cached_response unless cached_response.key?("fingerprint")

        if fingerprint_matches?(cached_response["fingerprint"], payload_fingerprint(payload))
          return cached_response["result"]
        end

        raise Payments::CreateCheckoutSession::ValidationError.new(
          { idempotency_key: "reused_with_different_payload" }
        )
      end

      def fingerprint_matches?(cached_fingerprint, current_fingerprint)
        return false if cached_fingerprint.blank? || current_fingerprint.blank?
        return false unless cached_fingerprint.bytesize == current_fingerprint.bytesize

        ActiveSupport::SecurityUtils.secure_compare(cached_fingerprint, current_fingerprint)
      end

      def payload_fingerprint(payload)
        Digest::SHA256.hexdigest(JSON.generate(payload.deep_stringify_keys.sort.to_h))
      end

      def create_session_params
        params.require(:order).permit(
          :order_id,
          :customer_email,
          :success_url,
          :cancel_url
        )
      end

      def retry_session_params
        params.require(:order).permit(
          :customer_email,
          :success_url,
          :cancel_url
        )
      end
    end
  end
end
