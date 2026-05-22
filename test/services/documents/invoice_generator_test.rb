require "test_helper"

class Documents::InvoiceGeneratorTest < ActiveSupport::TestCase
  setup do
    category = Category.create!(name: "Tests Facture", slug: "tests-facture", position: 1)
    product = Product.create!(
      category: category,
      name: "Burger test",
      description: "Produit facture",
      price_cents: 2500,
      currency: "EUR",
      active: true,
      stock_quantity: 10,
      badges: []
    )

    @user = User.create!(email: "test@example.com", password: "password123", role: "customer")
    @order = @user.orders.create!(
      order_number: "ORD-TEST-001",
      status: "confirmed",
      payment_status: "paid",
      service_mode: "delivery",
      subtotal_cents: 5000,
      delivery_fee_cents: 500,
      total_cents: 5500,
      customer_email: @user.email,
      customer_phone: "0600000010"
    )

    @order.order_items.create!(
      product: product,
      name: product.name,
      quantity: 2,
      unit_price_cents: 2500,
      line_total_cents: 5000,
      options: {}
    )

    @invoice = Invoice.create!(
      order: @order,
      invoice_number: "INV-#{SecureRandom.hex(4).upcase}",
      status: "issued",
      total_cents: 5500,
      issued_at: Time.current
    )
  end

  test "generates valid PDF content" do
    pdf_content = Documents::InvoiceGenerator.new(@invoice).generate_pdf

    assert pdf_content.present?
    assert pdf_content.is_a?(String)
    assert pdf_content.start_with?("%PDF")
  end

  test "PDF contains invoice number" do
    pdf_content = Documents::InvoiceGenerator.new(@invoice).generate_pdf

    assert_includes pdf_content, "/Type /Catalog"
    assert_includes pdf_content, "/Type /Page"
  end
end
