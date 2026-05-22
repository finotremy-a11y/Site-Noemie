class CartController < ApplicationController
  def show
    if user_signed_in?
      @cart = current_user.current_cart
    elsif session[:cart_session_token]
      @cart = Cart.find_by(session_token: session[:cart_session_token])
    end

    @cart ||= Cart.new
    @cart_items = @cart.cart_items.includes(:product) if @cart.persisted?
  end

  def add_item
    product = Product.find(params[:product_id])
    quantity = (params[:quantity] || 1).to_i
    special_instructions = params[:special_instructions]

    cart = get_or_create_cart

    existing_item = cart.cart_items.find_by(product_id: product.id)

    if existing_item
      updated_options = existing_item.options.merge("special_instructions" => special_instructions).compact
      existing_item.update(quantity: existing_item.quantity + quantity, options: updated_options)
    else
      cart.cart_items.create(
        product: product,
        quantity: quantity,
        unit_price_cents: product.price_cents,
        options: { "special_instructions" => special_instructions }.compact
      )
    end

    Cart::Recalculate.new(cart: cart).call

    redirect_back fallback_location: catalog_path, notice: "#{product.name} ajouté au panier"
  end

  def remove_item
    cart = get_or_create_cart
    cart_item = cart.cart_items.find(params[:id])
    cart_item.destroy

    Cart::Recalculate.new(cart: cart).call

    redirect_to cart_path, notice: "Article supprimé du panier"
  end

  def update_item
    cart = get_or_create_cart
    cart_item = cart.cart_items.find(params[:id])

    if params[:quantity].to_i > 0
      cart_item.update(quantity: params[:quantity].to_i)
      Cart::Recalculate.new(cart: cart).call
      redirect_to cart_path, notice: "Panier mis à jour"
    else
      cart_item.destroy
      redirect_to cart_path, notice: "Article supprimé du panier"
    end
  end

  private

  def get_or_create_cart
    if user_signed_in?
      return current_user.find_or_create_cart
    end

    if session[:cart_session_token]
      cart = Cart.find_by(session_token: session[:cart_session_token])
      return cart if cart
    end

    cart = Cart.create!(status: "open", session_token: SecureRandom.hex(16))
    session[:cart_session_token] = cart.session_token
    cart
  end
end
