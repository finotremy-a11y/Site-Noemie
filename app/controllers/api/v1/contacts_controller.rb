module Api
  module V1
    class ContactsController < BaseController
      def create
        contact = ContactRequest.new(contact_params)

        if contact.save
          Notifications::InquiryNotificationJob.perform_later(
            subject: "[N&L Cuisinent] Nouveau message de contact",
            lines: [
              "Nom: #{contact.name}",
              "Email: #{contact.email}",
              "Message:",
              contact.message
            ]
          )

          render json: {
            data: {
              id: contact.id,
              status: "received"
            }
          }, status: :created
        else
          render_error(
            code: "validation_error",
            message: "Parametres invalides.",
            details: { errors: contact.errors.full_messages },
            status: :unprocessable_entity
          )
        end
      end

      private

      def contact_params
        params.require(:contact).permit(:name, :email, :message)
      end
    end
  end
end
