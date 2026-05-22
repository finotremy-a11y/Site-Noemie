module Api
  module V1
    module Auth
      class SessionsController < Api::V1::BaseController
        def create
          payload = session_params
          email = payload.fetch(:email).to_s.strip.downcase

          if email.blank?
            return render_error(
              code: "validation_error",
              message: "Parametres invalides.",
              details: { email: "required" },
              status: :unprocessable_entity
            )
          end

          user = User.find_or_initialize_by(email: email)
          user.assign_attributes(
            full_name: payload[:full_name],
            phone: payload[:phone],
            role: user.role.presence || "customer",
            active: true
          )
          user.regenerate_api_token if user.api_token.blank?
          user.save!

          render json: {
            data: {
              token: user.api_token,
              user: serialize_user(user)
            }
          }, status: :created
        rescue ActionController::ParameterMissing => error
          render_error(
            code: "bad_request",
            message: error.message,
            status: :bad_request
          )
        rescue ActiveRecord::RecordInvalid => error
          render_error(
            code: "validation_error",
            message: "Parametres invalides.",
            details: { errors: error.record.errors.full_messages },
            status: :unprocessable_entity
          )
        end

        private

        def session_params
          params.require(:user).permit(:email, :full_name, :phone)
        end

        def serialize_user(user)
          {
            id: user.id,
            email: user.email,
            full_name: user.full_name,
            phone: user.phone,
            role: user.role,
            active: user.active
          }
        end
      end
    end
  end
end
