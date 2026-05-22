require "test_helper"

class PagesSmokeTest < ActionDispatch::IntegrationTest
  setup do
    @category = Category.create!(name: "Smoke", slug: "smoke", position: 1)
    @product = Product.create!(
      category: @category,
      name: "Produit Smoke",
      description: "Produit de test",
      price_cents: 1200,
      currency: "EUR",
      active: true,
      stock_quantity: 10,
      badges: []
    )

    @customer = User.create!(
      email: "smoke-customer@example.com",
      password: "password123",
      role: "customer"
    )

    @order = Order.create!(
      user: @customer,
      status: "confirmed",
      payment_status: "paid",
      service_mode: "pickup",
      customer_email: @customer.email,
      customer_phone: "0600000011",
      subtotal_cents: 1200,
      delivery_fee_cents: 0,
      total_cents: 1200
    )

    @order.order_items.create!(
      product: @product,
      name: @product.name,
      quantity: 1,
      unit_price_cents: 1200,
      line_total_cents: 1200,
      options: {}
    )

    @pending_order = Order.create!(
      user: @customer,
      status: "pending_payment",
      payment_status: "pending",
      service_mode: "pickup",
      customer_email: @customer.email,
      customer_phone: "0600000012",
      subtotal_cents: 1200,
      delivery_fee_cents: 0,
      total_cents: 1200
    )
    @pending_order.order_items.create!(
      product: @product,
      name: @product.name,
      quantity: 1,
      unit_price_cents: 1200,
      line_total_cents: 1200,
      options: {}
    )

    @address = @customer.addresses.create!(
      address_type: "delivery",
      full_name: "Client Smoke",
      street: "1 rue Smoke",
      city: "Paris",
      postal_code: "75001",
      country: "FR",
      phone: "0600000013",
      is_default: true
    )

    @review = @customer.reviews.create!(rating: 5, comment: "Super", status: "approved", order: @order)
    @quote = Quote.create!(email: @customer.email, status: "new", event_date: 7.days.from_now)

    @invoice = @order.create_invoice!(
      invoice_number: "INV-SMOKE-#{SecureRandom.hex(4).upcase}",
      status: "issued",
      total_cents: 1200,
      issued_at: Time.current,
      pdf_url: "https://example.test/invoice.pdf"
    )

    @admin = User.create!(
      email: "nl.cuisinent@gmail.com",
      password: "password123",
      role: "admin"
    )

    @audit_log = AuditLog.create!(
      user: @admin,
      action: "update",
      resource_type: "Order",
      resource_id: @order.id,
      metadata: { status: [ "pending_payment", "confirmed" ] },
      request_id: SecureRandom.uuid
    )

    cart = @customer.find_or_create_cart
    cart.cart_items.create!(product: @product, quantity: 1, unit_price_cents: 1200, options: {})
    Cart::Recalculate.new(cart: cart).call
  end

  test "public pages render without duplicate global bars" do
    [
      root_path,
      catalog_path,
      product_path(@product),
      contact_path,
      reviews_path,
      mentions_legales_path,
      politique_confidentialite_path,
      conditions_generales_path,
      login_path,
      register_path,
      cart_path
    ].each do |path|
      get path
      assert_response :success, "Expected #{path} to render successfully"
      assert_single_global_chrome
    end

    get mentions_legales_path
    assert_includes response.body, "97920047400026"
    assert_includes response.body, "1463 route d'avignon"
    assert_includes response.body, "nl.cuisinent@gmail.com"
  end

  test "guest can reach checkout before login" do
    post cart_items_path, params: { product_id: @product.id, quantity: 1 }
    assert_response :redirect

    get checkout_path
    assert_response :success
    assert_includes response.body, "Se connecter pour commander"
    assert_single_global_chrome
  end

  test "customer pages render after login" do
    login_as(@customer)

    [
      me_path,
      edit_me_path,
      me_orders_path,
      me_order_path(@order),
      me_addresses_path,
      me_new_address_path,
      me_edit_address_path(@address),
      me_preferences_path,
      me_invoices_path,
      me_invoice_path(@invoice),
      order_success_path(@order),
      order_cancel_path(@pending_order),
      checkout_path,
      new_review_path
    ].each do |path|
      get path
      assert_response :success, "Expected #{path} to render successfully"
      assert_single_global_chrome
    end

    get edit_review_path(@review)
    assert_response :success
    assert_single_global_chrome
  end

  test "admin pages render after login" do
    login_as(@admin)

    [
      admin_root_path,
      admin_dashboard_path,
      admin_orders_path,
      admin_order_path(@order),
      admin_products_path,
      new_admin_product_path,
      edit_admin_product_path(@product),
      admin_product_path(@product),
      admin_quotes_path,
      admin_quote_path(@quote),
      admin_reviews_path,
      admin_review_path(@review),
      admin_invoices_path,
      admin_invoice_path(@invoice),
      admin_audit_logs_path,
      admin_audit_log_path(@audit_log)
    ].each do |path|
      get path
      assert_response :success, "Expected #{path} to render successfully"
    end
  end

  private

  def login_as(user)
    post auth_login_path, params: { email: user.email, password: "password123" }
    assert_response :redirect
    follow_redirect!
    assert_response :success
  end

  def assert_single_global_chrome
    assert_equal 1, response.body.scan('class="status-bar"').count
    assert_equal 1, response.body.scan('class="header"').count
    assert_equal 1, response.body.scan('class="footer"').count
  end
end
