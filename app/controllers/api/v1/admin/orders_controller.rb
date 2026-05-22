module Api
  module V1
    module Admin
      class OrdersController < BaseController
        def index
          scope = Order.includes(:order_items).order(created_at: :desc, id: :desc)
          scope = scope.where(status: params[:status]) if params[:status].present?
          scope = scope.where(payment_status: params[:payment_status]) if params[:payment_status].present?

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

        def status
          order = Order.find_by(id: params[:id])
          return render_not_found unless order

          result = Orders::TransitionStatus.new(
            order: order,
            to_status: status_params.fetch(:status),
            actor: current_user,
            request_id: request.request_id,
            reason: status_params[:reason]
          ).call

          render json: {
            data: serialize_order(result)
          }, status: :ok
        rescue Orders::TransitionStatus::ValidationError => error
          render_error(
            code: "validation_error",
            message: "Transition de statut invalide.",
            details: error.details,
            status: :unprocessable_entity
          )
        rescue Orders::TransitionStatus::ConflictError => error
          render_error(
            code: "status_conflict",
            message: "Transition de statut refusee.",
            details: error.details,
            status: :conflict
          )
        end

        private

        def status_params
          params.require(:order).permit(:status, :reason)
        end

        def render_not_found
          render_error(
            code: "not_found",
            message: "Commande introuvable.",
            status: :not_found
          )
        end

        def serialize_order(order)
          {
            id: order.id,
            order_number: order.order_number,
            status: order.status,
            payment_status: order.payment_status,
            service_mode: order.service_mode,
            customer_email: order.customer_email,
            customer_phone: order.customer_phone,
            total_cents: order.total_cents,
            item_count: order.order_items.sum(&:quantity),
            created_at: order.created_at,
            updated_at: order.updated_at
          }
        end
      end
    end
  end
end
