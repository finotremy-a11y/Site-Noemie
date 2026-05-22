require "test_helper"

class CheckoutControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "checkout-web@test.com",
      password: "password123",
      role: "customer"
    )
    category = Category.create!(name: "Checkout Test", slug: "checkout-test", position: 1)
    product = Product.create!(
      category: category,
      name: "Produit checkout",
      description: "Produit de test",
      price_cents: 1800,
      currency: "EUR",
      active: true,
      stock_quantity: 10,
      badges: []
    )
    @order = Order.create!(
      user: @user,
      status: "confirmed",
      payment_status: "paid",
      service_mode: "pickup",
      customer_email: @user.email,
      customer_phone: "0600000008",
      subtotal_cents: 2400,
      delivery_fee_cents: 0,
      total_cents: 2400
    )
    @pending_order = Order.create!(
      user: @user,
      status: "pending_payment",
      payment_status: "pending",
      service_mode: "pickup",
      customer_email: @user.email,
      customer_phone: "0600000009",
      subtotal_cents: 1800,
      delivery_fee_cents: 0,
      total_cents: 1800
    )
    @pending_order.order_items.create!(
      product: product,
      name: product.name,
      quantity: 1,
      unit_price_cents: 1800,
      line_total_cents: 1800,
      options: {}
    )
  end

  test "success page loads the current user order by route id" do
    login_as_user

    get order_success_path(@order)

    assert_response :success
    assert_includes response.body, @order.order_number
  end

  test "cancel page loads the current user order by route id" do
    login_as_user

    get order_cancel_path(@order)

    assert_response :success
    assert_includes response.body, @order.order_number
  end

  test "retry payment redirects to stripe checkout for current user order" do
    login_as_user
    fake_session = OpenStruct.new(id: "cs_web_retry", url: "https://checkout.test/web-retry")

    Stripe::Checkout::Session.stub(:create, fake_session) do
      post order_retry_payment_path(@pending_order)
    end

    assert_redirected_to "https://checkout.test/web-retry"
  end

  test "retry payment redirects back to order page when order is not payable" do
    login_as_user

    post order_retry_payment_path(@order)

    assert_redirected_to me_order_path(@order)
  end

  private

  def login_as_user
    post auth_login_path, params: {
      email: @user.email,
      password: "password123"
    }
  end
end
