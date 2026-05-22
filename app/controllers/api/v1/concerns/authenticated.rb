module Api
  module V1
    module Concerns
      module Authenticated
        extend ActiveSupport::Concern

        included do
          rescue_from UnauthorizedError, with: :render_unauthorized
        end

        class UnauthorizedError < StandardError; end

        private

        def authenticate_user!
          require_customer! unless current_user
        end

        def authenticate_admin!
          return if current_user&.admin? && current_user.active?

          render_error(
            code: "forbidden",
            message: "Accès admin requis.",
            status: :forbidden
          )
        end

        def render_unauthorized(error)
          render_error(
            code: "unauthorized",
            message: error.message,
            status: :unauthorized
          )
        end
      end
    end
  end
end
