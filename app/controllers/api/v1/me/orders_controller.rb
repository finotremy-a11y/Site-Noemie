module Api
  module V1
    module Me
      class OrdersController < Api::V1::BaseController
        before_action :require_customer!

        def index
          scope = current_user.orders.includes(:order_items).order(created_at: :desc, id: :desc)

          page = [ params.fetch(:page, 1).to_i, 1 ].max
          per_page = [ params.fetch(:per_page, 20).to_i, 100 ].min
          offset = (page - 1) * per_page

          total = scope.count
          orders = scope.limit(per_page).offset(offset)

          render json: {
            data: orders.map { |order| serialize_order(order) },
            meta: {
              page: page,
              per_page: per_page,
              total: total
            }
          }, status: :ok
        end

        def show
          order = current_user.orders.includes(:order_items).find_by(id: params[:id])
          return render_not_found unless order

          render json: { data: serialize_order(order, detailed: true) }, status: :ok
        end

        private

        def render_not_found
          render_error(
            code: "not_found",
            message: "Commande introuvable.",
            status: :not_found
          )
        end

        def serialize_order(order, detailed: false)
          payload = {
            id: order.id,
            order_number: order.order_number,
            status: order.status,
            payment_status: order.payment_status,
            service_mode: order.service_mode,
            requested_at: order.requested_at,
            subtotal_cents: order.subtotal_cents,
            delivery_fee_cents: order.delivery_fee_cents,
            total_cents: order.total_cents,
            created_at: order.created_at,
            updated_at: order.updated_at
          }

          return payload unless detailed

          payload.merge(
            customer_email: order.customer_email,
            customer_phone: order.customer_phone,
            delivery_address: order.delivery_address,
            items: order.order_items.map do |item|
              {
                id: item.id,
                product_id: item.product_id,
                name: item.name,
                quantity: item.quantity,
                unit_price_cents: item.unit_price_cents,
                line_total_cents: item.line_total_cents,
                options: item.options
              }
            end
          )
        end
      end
    end
  end
end
