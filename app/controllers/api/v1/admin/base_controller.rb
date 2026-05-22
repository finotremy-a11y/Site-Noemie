module Api
  module V1
    module Admin
      class BaseController < Api::V1::BaseController
        before_action :require_admin_token!

        private

        def require_admin_token!
          expected_token = ENV["ADMIN_API_TOKEN"].to_s
          provided_token = request.headers["X-Admin-Token"].to_s

          token_valid = expected_token.present? &&
            provided_token.present? &&
            ActiveSupport::SecurityUtils.secure_compare(provided_token, expected_token)

          unless token_valid
            render_error(
              code: "forbidden",
              message: "Acces admin refuse.",
              status: :forbidden
            )
            return
          end

          return if current_user&.admin? && current_user.active?

          render_error(
            code: "forbidden",
            message: "Acces admin refuse.",
            status: :forbidden
          )
          nil
        end
      end
    end
  end
end
