module Api
  module V1
    module Me
      class InvoicesController < BaseController
        before_action :authenticate_user!

        def index
          invoices = current_user.orders
                                  .includes(:invoice)
                                  .map(&:invoice)
                                  .compact
                                  .sort_by(&:issued_at)
                                  .reverse

          render json: {
            data: invoices.map { |inv| serialize_invoice(inv) }
          }
        end

        def show
          invoice = find_user_invoice(params[:id])
          render json: { data: serialize_invoice(invoice) }
        rescue ActiveRecord::RecordNotFound
          render_error(code: "not_found", message: "Facture non trouvée", status: :not_found)
        end

        def download
          invoice = find_user_invoice(params[:id])

          unless invoice.pdf_ready?
            return render_error(
              code: "processing",
              message: "La facture est en cours de génération. Veuillez réessayer dans quelques instants.",
              status: :accepted
            )
          end

          redirect_to invoice.pdf_url, allow_other_host: true
        rescue ActiveRecord::RecordNotFound
          render_error(code: "not_found", message: "Facture non trouvée", status: :not_found)
        end

        private

        def find_user_invoice(invoice_id)
          Invoice.find(invoice_id).tap do |invoice|
            raise ActiveRecord::RecordNotFound unless invoice.order.user_id == current_user.id
          end
        end

        def serialize_invoice(invoice)
          {
            id: invoice.id,
            invoice_number: invoice.invoice_number,
            order_id: invoice.order.id,
            order_number: invoice.order.order_number,
            status: invoice.status,
            subtotal_cents: invoice.order.subtotal_cents,
            tax_cents: 0,
            total_cents: invoice.total_cents,
            issued_at: invoice.issued_at,
            pdf_url: invoice.pdf_url,
            pdf_ready: invoice.pdf_ready?
          }
        end
      end
    end
  end
end
