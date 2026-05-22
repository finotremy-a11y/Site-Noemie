module Api
  module V1
    class CartItemsController < BaseController
      def create
        cart = current_cart
        payload = item_params.to_h

        product = Product.active.in_season.find_by(id: payload.fetch("product_id"))
        return render_unavailable_product unless product

        quantity = payload.fetch("quantity").to_i
        return render_invalid_quantity if quantity <= 0
        return render_insufficient_stock if product.stock_quantity < quantity

        item = cart.cart_items.find_or_initialize_by(product_id: product.id, options: payload["options"] || {})
        item.quantity = quantity

        if item.save
          render json: {
            data: {
              id: item.id,
              product_id: item.product_id,
              quantity: item.quantity,
              unit_price_cents: item.unit_price_cents,
              line_total_cents: item.line_total_cents,
              options: item.options
            }
          }, status: :created
        else
          render_error(
            code: "validation_error",
            message: "Parametres invalides.",
            details: { errors: item.errors.full_messages },
            status: :unprocessable_entity
          )
        end
      rescue Cart::ResolveCurrentCart::ValidationError => error
        render_error(
          code: "validation_error",
          message: "Parametres invalides.",
          details: error.details,
          status: :unprocessable_entity
        )
      end

      def update
        cart = current_cart
        item = cart.cart_items.find_by(id: params[:id])
        return render_not_found unless item

        quantity = params.require(:quantity).to_i
        return render_invalid_quantity if quantity <= 0
        return render_insufficient_stock if item.product.stock_quantity < quantity

        item.update!(quantity: quantity)

        render json: {
          data: {
            id: item.id,
            quantity: item.quantity,
            unit_price_cents: item.unit_price_cents,
            line_total_cents: item.line_total_cents
          }
        }, status: :ok
      rescue ActionController::ParameterMissing => error
        render_error(
          code: "bad_request",
          message: error.message,
          status: :bad_request
        )
      rescue Cart::ResolveCurrentCart::ValidationError => error
        render_error(
          code: "validation_error",
          message: "Parametres invalides.",
          details: error.details,
          status: :unprocessable_entity
        )
      end

      def destroy
        cart = current_cart
        item = cart.cart_items.find_by(id: params[:id])
        return render_not_found unless item

        item.destroy!
        head :no_content
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

      def item_params
        params.require(:item).permit(:product_id, :quantity, options: {})
      end

      def render_unavailable_product
        render_error(
          code: "product_unavailable",
          message: "Produit indisponible.",
          status: :unprocessable_entity
        )
      end

      def render_invalid_quantity
        render_error(
          code: "validation_error",
          message: "Quantite invalide.",
          details: { quantity: "must be greater than 0" },
          status: :unprocessable_entity
        )
      end

      def render_insufficient_stock
        render_error(
          code: "stock_conflict",
          message: "Stock insuffisant.",
          status: :conflict
        )
      end

      def render_not_found
        render_error(
          code: "not_found",
          message: "Ligne de panier introuvable.",
          status: :not_found
        )
      end
    end
  end
end
