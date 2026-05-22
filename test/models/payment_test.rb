require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  setup do
    category = Category.create!(name: "Validation", slug: "validation", position: 1)
    product = Product.create!(
      category: category,
      name: "Produit test",
      description: "Test",
      price_cents: 1000,
      currency: "EUR",
      active: true,
      stock_quantity: 10,
      badges: []
    )

    @order = Order.create!(
      status: "pending_payment",
      payment_status: "pending",
      service_mode: "pickup",
      customer_email: "payment-test@example.com",
      customer_phone: "0600000004",
      subtotal_cents: 1000,
      delivery_fee_cents: 0,
      total_cents: 1000
    )
    @order.order_items.create!(
      product: product,
      name: product.name,
      quantity: 1,
      unit_price_cents: 1000,
      line_total_cents: 1000,
      options: {}
    )
  end

  test "idempotency key must be unique per provider" do
    Payment.create!(
      order: @order,
      provider: "stripe",
      status: "pending",
      amount_cents: 1000,
      currency: "EUR",
      idempotency_key: "idem-model-1"
    )

    duplicate = Payment.new(
      order: @order,
      provider: "stripe",
      status: "pending",
      amount_cents: 1000,
      currency: "EUR",
      idempotency_key: "idem-model-1"
    )

    assert_not duplicate.valid?
    assert duplicate.errors[:idempotency_key].any?
  end
end
