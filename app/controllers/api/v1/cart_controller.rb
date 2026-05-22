module Api
  module V1
    class CartController < BaseController
      def show
        cart = current_cart
        totals = Cart::Recalculate.new(cart: cart, service_mode: params[:service_mode].presence || "pickup").call

        render json: {
          data: {
            id: cart.id,
            session_token: cart.session_token,
            status: cart.status,
            items: cart.cart_items.includes(:product).map { |item| serialize_item(item) },
            totals: {
              subtotal_cents: totals.subtotal_cents,
              delivery_fee_cents: totals.delivery_fee_cents,
              total_cents: totals.total_cents
            }
          }
        }, status: :ok
      rescue Cart::ResolveCurrentCart::ValidationError => error
        render_error(
          code: "validation_error",
          message: "Parametres invalides.",
          details: error.details,
          status: :unprocessable_entity
        )
      end

      private

      def current_cart
        Cart::ResolveCurrentCart.new(session_token: cart_token, user_id: current_user&.id).call
      end

      def cart_token
        request.headers["X-Cart-Token"].presence || params[:session_token]
      end

      def serialize_item(item)
        {
          id: item.id,
          product_id: item.product_id,
          name: item.product.name,
          quantity: item.quantity,
          unit_price_cents: item.unit_price_cents,
          line_total_cents: item.line_total_cents,
          options: item.options
        }
      end
    end
  end
end
