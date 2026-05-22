module Api
  module V1
    class QuotesController < BaseController
      def create
        quote = Quote.new(quote_params)

        if quote.save
          Notifications::InquiryNotificationJob.perform_later(
            subject: "[N&L Cuisinent] Nouvelle demande de devis",
            lines: [
              "Email: #{quote.email}",
              "Telephone: #{quote.phone}",
              "Type d'evenement: #{quote.event_type}",
              "Nombre d'invites: #{quote.guest_count}",
              "Date: #{quote.event_date}",
              "Lieu: #{quote.location}",
              "Budget (cents): #{quote.budget_cents}",
              "Contraintes:",
              quote.constraints.to_s,
              "Message:",
              quote.message.to_s
            ]
          )

          render json: {
            data: serialize_quote(quote)
          }, status: :created
        else
          render_error(
            code: "validation_error",
            message: "Parametres invalides.",
            details: { errors: quote.errors.full_messages },
            status: :unprocessable_entity
          )
        end
      end

      private

      def quote_params
        params.require(:quote).permit(
          :email,
          :phone,
          :event_type,
          :guest_count,
          :event_date,
          :location,
          :budget_cents,
          :constraints,
          :message
        )
      end

      def serialize_quote(quote)
        {
          id: quote.id,
          email: quote.email,
          status: quote.status,
          event_type: quote.event_type,
          event_date: quote.event_date,
          guest_count: quote.guest_count,
          created_at: quote.created_at
        }
      end
    end
  end
end
