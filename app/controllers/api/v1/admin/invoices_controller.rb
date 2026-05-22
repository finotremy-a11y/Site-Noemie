module Api
  module V1
    module Admin
      class InvoicesController < BaseController
        def index
          scope = Invoice.includes(:order).order(issued_at: :desc, id: :desc)
          scope = scope.where(status: params[:status]) if params[:status].present?

          render json: {
            data: scope.limit(200).map { |invoice| serialize_invoice(invoice) }
          }, status: :ok
        end

        def show
          invoice = Invoice.includes(:order).find_by(id: params[:id])
          return render_not_found unless invoice

          render json: {
            data: serialize_invoice(invoice)
          }, status: :ok
        end

        private

        def render_not_found
          render_error(
            code: "not_found",
            message: "Facture introuvable.",
            status: :not_found
          )
        end

        def serialize_invoice(invoice)
          {
            id: invoice.id,
            invoice_number: invoice.invoice_number,
            order_id: invoice.order_id,
            order_number: invoice.order&.order_number,
            total_cents: invoice.total_cents,
            status: invoice.status,
            issued_at: invoice.issued_at,
            created_at: invoice.created_at
          }
        end
      end
    end
  end
end
