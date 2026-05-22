require "test_helper"

module Payments
  class CreateCheckoutSessionTest < ActiveSupport::TestCase
    setup do
      @category = Category.create!(name: "Tests", slug: "tests", position: 1)
    end

    test "uses order currency consistently for stripe line items and payment record" do
      product = Product.create!(
        category: @category,
        name: "Burger USD",
        description: "Produit en USD",
        price_cents: 2000,
        currency: "USD",
        active: true,
        stock_quantity: 5,
        badges: []
      )

      order = Order.create!(
        status: "pending_payment",
        payment_status: "pending",
        service_mode: "pickup",
        customer_email: "usd@test.com",
        customer_phone: "0600000002",
        subtotal_cents: 2000,
        delivery_fee_cents: 0,
        total_cents: 2000
      )
      order.order_items.create!(
        product: product,
        name: product.name,
        quantity: 1,
        unit_price_cents: 2000,
        line_total_cents: 2000,
        options: {}
      )

      captured_session_args = nil
      fake_session = OpenStruct.new(id: "cs_usd_1", url: "https://checkout.test/usd")

      Stripe::Checkout::Session.stub(:create, ->(args, _opts) {
        captured_session_args = args
        fake_session
      }) do
        result = CreateCheckoutSession.new(
          payload: {
            "order_id" => order.id,
            "success_url" => "https://example.com/success",
            "cancel_url" => "https://example.com/cancel"
          },
          idempotency_key: "svc-idem-1"
        ).call

        assert_equal order.id, result[:order_id]
      end

      assert_equal "manual", captured_session_args.dig(:payment_intent_data, :capture_method)
      assert_equal "usd", captured_session_args[:line_items].first[:price_data][:currency]
      assert_equal "USD", order.payments.last.currency
    end

    test "rejects checkout for mixed-currency order items" do
      product_eur = Product.create!(
        category: @category,
        name: "Produit EUR",
        description: "Produit en EUR",
        price_cents: 1000,
        currency: "EUR",
        active: true,
        stock_quantity: 5,
        badges: []
      )
      product_usd = Product.create!(
        category: @category,
        name: "Produit USD",
        description: "Produit en USD",
        price_cents: 1500,
        currency: "USD",
        active: true,
        stock_quantity: 5,
        badges: []
      )

      order = Order.create!(
        status: "pending_payment",
        payment_status: "pending",
        service_mode: "pickup",
        customer_email: "mixed@test.com",
        customer_phone: "0600000003",
        subtotal_cents: 2500,
        delivery_fee_cents: 0,
        total_cents: 2500
      )
      order.order_items.create!(
        product: product_eur,
        name: product_eur.name,
        quantity: 1,
        unit_price_cents: 1000,
        line_total_cents: 1000,
        options: {}
      )
      order.order_items.create!(
        product: product_usd,
        name: product_usd.name,
        quantity: 1,
        unit_price_cents: 1500,
        line_total_cents: 1500,
        options: {}
      )

      error = assert_raises(CreateCheckoutSession::ValidationError) do
        CreateCheckoutSession.new(
          payload: {
            "order_id" => order.id,
            "success_url" => "https://example.com/success",
            "cancel_url" => "https://example.com/cancel"
          }
        ).call
      end

      assert_equal "order items must use a single currency", error.details[:currency]
    end

    test "reuses payment record for same idempotency key and same order" do
      product = Product.create!(
        category: @category,
        name: "Produit idem",
        description: "Idempotence",
        price_cents: 1800,
        currency: "EUR",
        active: true,
        stock_quantity: 5,
        badges: []
      )

      order = Order.create!(
        status: "pending_payment",
        payment_status: "pending",
        service_mode: "pickup",
        customer_email: "idem@test.com",
        customer_phone: "0600000005",
        subtotal_cents: 1800,
        delivery_fee_cents: 0,
        total_cents: 1800
      )
      order.order_items.create!(
        product: product,
        name: product.name,
        quantity: 1,
        unit_price_cents: 1800,
        line_total_cents: 1800,
        options: {}
      )

      fake_session = OpenStruct.new(id: "cs_idem_same", url: "https://checkout.test/idem-same")

      Stripe::Checkout::Session.stub(:create, fake_session) do
        Stripe::Checkout::Session.stub(:retrieve, fake_session) do
          first = CreateCheckoutSession.new(
            payload: {
              "order_id" => order.id,
              "success_url" => "https://example.com/success",
              "cancel_url" => "https://example.com/cancel"
            },
            idempotency_key: "svc-idem-same"
          ).call

          second = CreateCheckoutSession.new(
            payload: {
              "order_id" => order.id,
              "success_url" => "https://example.com/success",
              "cancel_url" => "https://example.com/cancel"
            },
            idempotency_key: "svc-idem-same"
          ).call

          assert_equal first[:payment_id], second[:payment_id]
        end
      end

      assert_equal 1, order.payments.where(idempotency_key: "svc-idem-same").count
    end

    test "rejects idempotency key reuse for another order" do
      product = Product.create!(
        category: @category,
        name: "Produit clash",
        description: "Conflit idem",
        price_cents: 1200,
        currency: "EUR",
        active: true,
        stock_quantity: 5,
        badges: []
      )

      order_one = Order.create!(
        status: "pending_payment",
        payment_status: "pending",
        service_mode: "pickup",
        customer_email: "one@test.com",
        customer_phone: "0600000006",
        subtotal_cents: 1200,
        delivery_fee_cents: 0,
        total_cents: 1200
      )
      order_one.order_items.create!(
        product: product,
        name: product.name,
        quantity: 1,
        unit_price_cents: 1200,
        line_total_cents: 1200,
        options: {}
      )

      order_two = Order.create!(
        status: "pending_payment",
        payment_status: "pending",
        service_mode: "pickup",
        customer_email: "two@test.com",
        customer_phone: "0600000007",
        subtotal_cents: 1200,
        delivery_fee_cents: 0,
        total_cents: 1200
      )
      order_two.order_items.create!(
        product: product,
        name: product.name,
        quantity: 1,
        unit_price_cents: 1200,
        line_total_cents: 1200,
        options: {}
      )

      fake_session = OpenStruct.new(id: "cs_idem_clash", url: "https://checkout.test/idem-clash")

      Stripe::Checkout::Session.stub(:create, fake_session) do
        CreateCheckoutSession.new(
          payload: {
            "order_id" => order_one.id,
            "success_url" => "https://example.com/success",
            "cancel_url" => "https://example.com/cancel"
          },
          idempotency_key: "svc-idem-clash"
        ).call

        error = assert_raises(CreateCheckoutSession::ValidationError) do
          CreateCheckoutSession.new(
            payload: {
              "order_id" => order_two.id,
              "success_url" => "https://example.com/success",
              "cancel_url" => "https://example.com/cancel"
            },
            idempotency_key: "svc-idem-clash"
          ).call
        end

        assert_equal "already_used_for_another_order", error.details[:idempotency_key]
      end
    end

    test "returns existing checkout session without creating a new one" do
      product = Product.create!(
        category: @category,
        name: "Produit existing session",
        description: "Reutilisation session",
        price_cents: 1600,
        currency: "EUR",
        active: true,
        stock_quantity: 5,
        badges: []
      )

      order = Order.create!(
        status: "pending_payment",
        payment_status: "pending",
        service_mode: "pickup",
        customer_email: "existing@test.com",
        customer_phone: "0600000008",
        subtotal_cents: 1600,
        delivery_fee_cents: 0,
        total_cents: 1600
      )
      order.order_items.create!(
        product: product,
        name: product.name,
        quantity: 1,
        unit_price_cents: 1600,
        line_total_cents: 1600,
        options: {}
      )

      payment = Payment.create!(
        order: order,
        provider: "stripe",
        provider_payment_id: "cs_existing_1",
        status: "pending",
        amount_cents: 1600,
        currency: "EUR",
        idempotency_key: "svc-existing-session"
      )

      created_calls = 0
      retrieved_session = OpenStruct.new(id: "cs_existing_1", url: "https://checkout.test/existing")

      Stripe::Checkout::Session.stub(:create, ->(*_args) { created_calls += 1 }) do
        Stripe::Checkout::Session.stub(:retrieve, retrieved_session) do
          result = CreateCheckoutSession.new(
            payload: {
              "order_id" => order.id,
              "success_url" => "https://example.com/success",
              "cancel_url" => "https://example.com/cancel"
            },
            idempotency_key: "svc-existing-session"
          ).call

          assert_equal payment.id, result[:payment_id]
          assert_equal "cs_existing_1", result[:checkout_session_id]
          assert_equal "https://checkout.test/existing", result[:checkout_url]
        end
      end

      assert_equal 0, created_calls
    end
  end
end
