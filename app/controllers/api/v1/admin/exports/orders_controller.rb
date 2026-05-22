module Api
  module V1
    module Admin
      module Exports
        class OrdersController < BaseController
          def csv
            orders = Order.includes(:order_items, :payments, :user)
            orders = apply_filters(orders)
            orders = apply_sort(orders)

            csv_content = generate_orders_csv(orders)

            send_data csv_content,
                      filename: "orders-#{Date.today}.csv",
                      type: "text/csv"
          end

          private

          def apply_filters(scope)
            filtered = scope

            filtered = filtered.where(status: params[:status]) if params[:status].present?
            if params[:payment_status].present?
              filtered = filtered.where(payment_status: params[:payment_status])
            end
            filtered = filtered.where(service_mode: params[:service_mode]) if params[:service_mode].present?

            if params[:q].present?
              query = "%#{params[:q].to_s.strip.downcase}%"
              filtered = filtered.where("LOWER(order_number) LIKE :query OR LOWER(customer_email) LIKE :query", query: query)
            end

            if params[:date_from].present?
              date_from = Date.parse(params[:date_from]) rescue nil
              filtered = filtered.where("orders.created_at >= ?", date_from.beginning_of_day) if date_from
            end

            if params[:date_to].present?
              date_to = Date.parse(params[:date_to]) rescue nil
              filtered = filtered.where("orders.created_at <= ?", date_to.end_of_day) if date_to
            end

            filtered
          end

          def apply_sort(scope)
            allowed_columns = %w[created_at order_number status payment_status total_cents service_mode]
            requested_column = params[:sort].to_s
            requested_direction = params[:direction].to_s

            column = allowed_columns.include?(requested_column) ? requested_column : "created_at"
            direction = %w[asc desc].include?(requested_direction) ? requested_direction : "desc"

            scope.order(column => direction)
          end

          def generate_orders_csv(orders)
            require "csv"

            CSV.generate(headers: true) do |csv|
              csv << [ "Numéro", "Client", "Email", "Statut", "Montant (€)", "Moyen de paiement", "Date" ]

              orders.each do |order|
                latest_payment = order.payments.max_by(&:created_at)
                csv << [
                  order.order_number,
                  order.user&.email&.split("@")&.first || "Anonyme",
                  order.user&.email || "N/A",
                  I18n.t("enums.order.status.#{order.status}"),
                  "%.2f" % (order.total_cents / 100.0),
                  latest_payment&.provider || "N/A",
                  order.created_at.strftime("%d/%m/%Y %H:%M")
                ]
              end
            end
          end
        end
      end
    end
  end
end
