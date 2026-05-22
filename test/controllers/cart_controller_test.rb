require "test_helper"

class CartControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.find_or_create_by!(email: "testcart@example.com") do |u|
      u.password = "password123"
      u.role = "customer"
    end
    @category = Category.find_or_create_by!(slug: "burgers-test") do |c|
      c.name = "Burgers Test"
      c.position = 99
      c.active = true
    end
    @product = Product.create!(
      name: "Classic Burger",
      description: "Le classique",
      price_cents: 1290,
      active: true,
      stock_quantity: 10,
      category: @category
    )
  end

  # ── SHOW ──────────────────────────────────────────────────────────────────

  test "cart show renders empty cart for guest" do
    get cart_path
    assert_response :success
    assert_includes response.body, "panier est vide"
  end

  test "cart show renders cart with items for logged-in user" do
    post "/auth/login", params: { email: @user.email, password: "password123" }
    cart = @user.find_or_create_cart
    CartItem.create!(cart: cart, product: @product, quantity: 2, unit_price_cents: @product.price_cents)
    Cart::Recalculate.new(cart: cart).call

    get cart_path
    assert_response :success
    assert_includes response.body, @product.name
  end

  # ── ADD ITEM ──────────────────────────────────────────────────────────────

  test "adding item to cart redirects to cart for guest" do
    post cart_items_path, params: { product_id: @product.id, quantity: 1 }
    assert_redirected_to cart_path
    assert_not_nil session[:cart_session_token]
    cart = Cart.find_by!(session_token: session[:cart_session_token])
    assert_equal 1, cart.cart_items.count
  end

  test "adding item to cart works for logged-in user" do
    post "/auth/login", params: { email: @user.email, password: "password123" }
    post cart_items_path, params: { product_id: @product.id, quantity: 2 }
    assert_redirected_to cart_path
    assert_equal 2, @user.reload.current_cart.cart_items.first.quantity
  end

  # ── UPDATE ITEM ───────────────────────────────────────────────────────────

  test "update item quantity increases quantity" do
    post "/auth/login", params: { email: @user.email, password: "password123" }
    cart = @user.find_or_create_cart
    item = CartItem.create!(cart: cart, product: @product, quantity: 1, unit_price_cents: @product.price_cents)
    Cart::Recalculate.new(cart: cart).call

    patch cart_item_path(item), params: { quantity: 3 }
    assert_redirected_to cart_path
    assert_equal 3, item.reload.quantity
  end

  test "update item removes it when quantity set to 0" do
    post "/auth/login", params: { email: @user.email, password: "password123" }
    cart = @user.find_or_create_cart
    item = CartItem.create!(cart: cart, product: @product, quantity: 2, unit_price_cents: @product.price_cents)
    Cart::Recalculate.new(cart: cart).call

    patch cart_item_path(item), params: { quantity: 0 }
    assert_redirected_to cart_path
    assert_nil CartItem.find_by(id: item.id)
  end

  # ── REMOVE ITEM ───────────────────────────────────────────────────────────

  test "delete item removes it from cart" do
    post "/auth/login", params: { email: @user.email, password: "password123" }
    cart = @user.find_or_create_cart
    item = CartItem.create!(cart: cart, product: @product, quantity: 1, unit_price_cents: @product.price_cents)
    Cart::Recalculate.new(cart: cart).call

    delete cart_item_path(item)
    assert_redirected_to cart_path
    assert_nil CartItem.find_by(id: item.id)
  end

  test "cart show displays only total price when quantity is 1" do
    post "/auth/login", params: { email: @user.email, password: "password123" }
    cart = @user.find_or_create_cart
    CartItem.create!(cart: cart, product: @product, quantity: 1, unit_price_cents: @product.price_cents)
    Cart::Recalculate.new(cart: cart).call

    get cart_path
    assert_response :success
    assert_no_match(/class="unit-price"/, response.body)
    assert_match(/class="total-price"/, response.body)
  end

  test "cart show still displays only total price when quantity > 1" do
    post "/auth/login", params: { email: @user.email, password: "password123" }
    cart = @user.find_or_create_cart
    CartItem.create!(cart: cart, product: @product, quantity: 3, unit_price_cents: @product.price_cents)
    Cart::Recalculate.new(cart: cart).call

    get cart_path
    assert_response :success
    assert_no_match(/class="unit-price"/, response.body)
    assert_match(/class="total-price"/, response.body)
  end

  test "cart summary displays HT, VAT, and TTC totals" do
    post "/auth/login", params: { email: @user.email, password: "password123" }
    cart = @user.find_or_create_cart
    CartItem.create!(cart: cart, product: @product, quantity: 1, unit_price_cents: @product.price_cents)
    Cart::Recalculate.new(cart: cart).call

    get cart_path
    assert_response :success
    assert_includes response.body, "Sous-total HT"
    assert_includes response.body, "TVA (20%)"
    assert_includes response.body, "Total TTC"
  end
end
