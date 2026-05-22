module Api
  module V1
    class MeController < BaseController
      before_action :require_customer!

      def show
        render json: { data: serialize_user(current_user) }, status: :ok
      end

      def update
        current_user.update!(me_params)
        render json: { data: serialize_user(current_user) }, status: :ok
      rescue ActiveRecord::RecordInvalid => error
        render_error(
          code: "validation_error",
          message: "Parametres invalides.",
          details: { errors: error.record.errors.full_messages },
          status: :unprocessable_entity
        )
      end

      def destroy
        current_user.update!(active: false)
        current_user.regenerate_api_token
        current_user.save!

        head :no_content
      end

      private

      def me_params
        params.require(:user).permit(:full_name, :phone)
      end

      def serialize_user(user)
        {
          id: user.id,
          email: user.email,
          full_name: user.full_name,
          phone: user.phone,
          role: user.role,
          active: user.active,
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      end
    end
  end
end
