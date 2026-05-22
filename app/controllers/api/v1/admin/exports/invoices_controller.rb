module Api
  module V1
    module Admin
      module Exports
        class InvoicesController < BaseController
          def csv
            invoices = Invoice.includes(order: :user)
            invoices = apply_filters(invoices)
            invoices = apply_sort(invoices)

            csv_content = generate_invoices_csv(invoices)

            send_data csv_content,
                      filename: "invoices-#{Date.today}.csv",
                      type: "text/csv"
          end

          private

          def apply_filters(scope)
            filtered = scope

            filtered = filtered.where(status: params[:status]) if params[:status].present?

            if params[:q].present?
              query = "%#{params[:q].to_s.strip.downcase}%"
              filtered = filtered.joins("LEFT JOIN orders ON orders.id = invoices.order_id")
                                 .where("LOWER(invoices.invoice_number) LIKE :query OR LOWER(orders.order_number) LIKE :query", query: query)
            end

            if params[:date_from].present?
              date_from = Date.parse(params[:date_from]) rescue nil
              if date_from
                filtered = filtered.where("COALESCE(invoices.issued_at, invoices.created_at) >= ?", date_from.beginning_of_day)
              end
            end

            if params[:date_to].present?
              date_to = Date.parse(params[:date_to]) rescue nil
              if date_to
                filtered = filtered.where("COALESCE(invoices.issued_at, invoices.created_at) <= ?", date_to.end_of_day)
              end
            end

            filtered
          end

          def apply_sort(scope)
            allowed_columns = %w[created_at issued_at total_cents status invoice_number]
            requested_column = params[:sort].to_s
            requested_direction = params[:direction].to_s

            column = allowed_columns.include?(requested_column) ? requested_column : "issued_at"
            direction = %w[asc desc].include?(requested_direction) ? requested_direction : "desc"

            scope.order(column => direction)
          end

          def generate_invoices_csv(invoices)
            require "csv"

            CSV.generate(headers: true) do |csv|
              csv << [ "Numéro de facture", "Numéro de commande", "Client", "Montant HT (€)", "TVA (€)", "Montant TTC (€)", "Date d'émission", "Statut" ]

              invoices.each do |invoice|
                csv << [
                  invoice.invoice_number,
                  invoice.order&.order_number || "N/A",
                  invoice.order&.user&.email || "N/A",
                  "%.2f" % (invoice.subtotal_cents / 100.0),
                  "%.2f" % (invoice.tax_cents / 100.0),
                  "%.2f" % (invoice.total_cents / 100.0),
                  invoice.issued_at.strftime("%d/%m/%Y"),
                  invoice.status
                ]
              end
            end
          end
        end
      end
    end
  end
end
