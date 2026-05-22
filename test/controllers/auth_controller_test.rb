require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @category = Category.create!(name: "Tests Auth", slug: "tests-auth", position: 1)
    @product = Product.create!(
      category: @category,
      name: "Produit login",
      description: "Produit de test",
      price_cents: 1200,
      currency: "EUR",
      active: true,
      stock_quantity: 10,
      badges: []
    )
    @user = User.create!(
      email: "client-auth@test.com",
      password: "password123",
      role: "customer"
    )
  end

  test "login redirects to originally requested page" do
    get me_path

    assert_redirected_to login_path

    post auth_login_path, params: {
      email: @user.email,
      password: "password123"
    }

    assert_redirected_to me_url
  end

  test "login merges guest cart into user cart" do
    post cart_items_path, params: {
      product_id: @product.id,
      quantity: 2,
      special_instructions: "Sans sauce"
    }

    assert_redirected_to cart_path
    guest_cart = Cart.where(user_id: nil).order(:created_at).last
    assert_not_nil guest_cart
    assert_equal 1, guest_cart.cart_items.count

    post auth_login_path, params: {
      email: @user.email,
      password: "password123"
    }

    assert_redirected_to me_path
    @user.reload
    user_cart = @user.current_cart
    assert_not_nil user_cart
    assert_equal 1, user_cart.cart_items.count
    assert_equal 2, user_cart.cart_items.first.quantity
    assert_equal "Sans sauce", user_cart.cart_items.first.options["special_instructions"]

    guest_cart.reload
    assert_equal "converted", guest_cart.status
    assert_equal @user.id, guest_cart.user_id
  end
end
