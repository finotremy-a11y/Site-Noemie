module Api
  module V1
    class OrdersController < BaseController
      IDEMPOTENCY_TTL = 30.minutes

      def create
        idempotency_key = request.headers["Idempotency-Key"].presence
        if idempotency_key
          cached_response = Rails.cache.read(cache_key_for(idempotency_key))
          return render json: cached_response, status: :created if cached_response
        end

        cart = Cart::ResolveCurrentCart.new(session_token: cart_token, user_id: current_user&.id).call
        order = Orders::CreateFromCart.new(cart: cart, attrs: order_params.to_h).call

        payload = {
          data: {
            id: order.id,
            order_number: order.order_number,
            status: order.status,
            payment_status: order.payment_status,
            service_mode: order.service_mode,
            subtotal_cents: order.subtotal_cents,
            delivery_fee_cents: order.delivery_fee_cents,
            total_cents: order.total_cents
          }
        }

        Rails.cache.write(cache_key_for(idempotency_key), payload, expires_in: IDEMPOTENCY_TTL) if idempotency_key

        render json: payload, status: :created
      rescue Orders::CreateFromCart::ValidationError => error
        render_error(
          code: "validation_error",
          message: "Commande invalide.",
          details: error.details,
          status: :unprocessable_entity
        )
      rescue Cart::ResolveCurrentCart::ValidationError => error
        render_error(
          code: "validation_error",
          message: "Parametres invalides.",
          details: error.details,
          status: :unprocessable_entity
        )
      end

      def show
        return require_customer! unless current_user

        order = Order.find_by(id: params[:id])
        return render_not_found unless order
        return render_forbidden if forbidden_for_current_user?(order)

        render json: {
          data: serialize_order(order)
        }, status: :ok
      end

      def status
        return require_customer! unless current_user

        order = Order.find_by(id: params[:id])
        return render_not_found unless order
        return render_forbidden if forbidden_for_current_user?(order)

        render json: {
          data: {
            id: order.id,
            order_number: order.order_number,
            status: order.status,
            payment_status: order.payment_status,
            updated_at: order.updated_at
          }
        }, status: :ok
      end

      private

      def cart_token
        request.headers["X-Cart-Token"].presence || params[:session_token]
      end

      def order_params
        params.require(:order).permit(
          :service_mode,
          :customer_email,
          :customer_phone,
          :delivery_address,
          :delivery_distance_km,
          :requested_at
        )
      end

      def cache_key_for(idempotency_key)
        "idem:orders:create:#{idempotency_key}"
      end

      def render_not_found
        render_error(
          code: "not_found",
          message: "Commande introuvable.",
          status: :not_found
        )
      end

      def render_forbidden
        render_error(
          code: "forbidden",
          message: "Acces refuse a cette commande.",
          status: :forbidden
        )
      end

      def forbidden_for_current_user?(order)
        return false unless current_user
        return false if order.user_id.blank?

        order.user_id != current_user.id
      end

      def serialize_order(order)
        {
          id: order.id,
          order_number: order.order_number,
          status: order.status,
          payment_status: order.payment_status,
          service_mode: order.service_mode,
          requested_at: order.requested_at,
          customer_email: order.customer_email,
          customer_phone: order.customer_phone,
          delivery_address: order.delivery_address,
          subtotal_cents: order.subtotal_cents,
          delivery_fee_cents: order.delivery_fee_cents,
          total_cents: order.total_cents,
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
        }
      end
    end
  end
end
