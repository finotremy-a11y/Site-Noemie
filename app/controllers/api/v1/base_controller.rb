module Api
  module V1
    class BaseController < ActionController::API
      include Api::V1::Concerns::Authenticated

      before_action :set_sentry_context

      rescue_from ActionController::ParameterMissing, with: :render_bad_request
      rescue_from StandardError, with: :render_internal_error

      private

      def current_user
        return @current_user if defined?(@current_user)

        token = request.headers["X-Customer-Token"].to_s
        @current_user = token.present? ? User.find_by(api_token: token, active: true) : nil
      end

      def require_customer!
        return if current_user

        render_error(
          code: "unauthorized",
          message: "Authentification requise.",
          status: :unauthorized
        )
      end

      def set_sentry_context
        return unless defined?(Sentry)

        Sentry.set_tags(
          api_version: "v1",
          request_id: request.request_id,
          action: "#{controller_name}##{action_name}",
          method: request.method
        )

        if current_user
          Sentry.set_user(
            id: current_user.id,
            email: current_user.email,
            username: current_user.email.split("@").first
          )
          Sentry.set_context("user_info", {
            role: current_user.role,
            created_at: current_user.created_at.to_s,
            orders_count: current_user.orders.count,
            is_active: current_user.active
          })
        end

        # Add business context from request
        if request.get_parameter_parser
          Sentry.set_context("api_request", {
            path: request.path,
            user_agent: request.user_agent&.first(100)
          })
        end
      rescue StandardError
        nil
      end

      def render_bad_request(error)
        render_error(
          code: "bad_request",
          message: error.message,
          details: {},
          status: :bad_request
        )
      end

      def render_error(code:, message:, details: {}, status:)
        render json: {
          error: {
            code: code,
            message: message,
            details: details
          }
        }, status: status
      end

      def render_internal_error(error)
        set_sentry_context
        Sentry.capture_exception(error) if defined?(Sentry)

        Rails.logger.error(
          {
            source: "api.v1",
            error_class: error.class.name,
            error_message: error.message,
            path: request.path,
            request_id: request.request_id
          }.to_json
        )

        render_error(
          code: "internal_error",
          message: "Une erreur interne est survenue.",
          status: :internal_server_error
        )
      end
    end
  end
end
