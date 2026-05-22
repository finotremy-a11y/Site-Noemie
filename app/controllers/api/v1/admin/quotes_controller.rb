module Api
  module V1
    module Admin
      class QuotesController < BaseController
        def index
          scope = Quote.order(created_at: :desc, id: :desc)
          scope = scope.where(status: params[:status]) if params[:status].present?

          render json: {
            data: scope.limit(200).map { |quote| serialize_quote(quote) }
          }, status: :ok
        end

        def show
          quote = Quote.find_by(id: params[:id])
          return render_not_found unless quote

          render json: { data: serialize_quote(quote) }, status: :ok
        end

        def status
          quote = Quote.find_by(id: params[:id])
          return render_not_found unless quote

          next_status = status_params.fetch(:status)
          unless Quote::STATUSES.include?(next_status)
            return render_error(
              code: "validation_error",
              message: "Statut invalide.",
              details: { allowed: Quote::STATUSES },
              status: :unprocessable_entity
            )
          end

          quote.update!(status: next_status)

          Notifications::CustomerNotificationJob.perform_later(
            to: quote.email,
            subject: "[N&L Cuisinent] Mise a jour de votre devis",
            lines: [
              "Votre demande de devis ##{quote.id} a ete mise a jour.",
              "Nouveau statut: #{next_status}"
            ]
          )

          AuditLog.create!(
            action: "quote_status_changed",
            resource_type: "Quote",
            resource_id: quote.id,
            request_id: request.request_id,
            metadata: {
              status: next_status,
              actor: "admin_api"
            }
          )

          render json: { data: serialize_quote(quote) }, status: :ok
        end

        private

        def status_params
          params.require(:quote).permit(:status)
        end

        def render_not_found
          render_error(
            code: "not_found",
            message: "Demande introuvable.",
            status: :not_found
          )
        end

        def serialize_quote(quote)
          {
            id: quote.id,
            email: quote.email,
            phone: quote.phone,
            event_type: quote.event_type,
            guest_count: quote.guest_count,
            event_date: quote.event_date,
            location: quote.location,
            budget_cents: quote.budget_cents,
            status: quote.status,
            message: quote.message,
            constraints: quote.constraints,
            created_at: quote.created_at,
            updated_at: quote.updated_at
          }
        end
      end
    end
  end
end
