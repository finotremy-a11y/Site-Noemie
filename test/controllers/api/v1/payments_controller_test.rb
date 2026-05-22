require "test_helper"

module Api
  module V1
    class PaymentsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @category = Category.find_or_create_by!(slug: "burgers-api-payments") do |category|
          category.name = "Burgers API Payments"
          category.position = 1
          category.active = true
        end
        @product = Product.create!(
          category: @category,
          name: "Burger Premium",
          description: "Double cheddar",
          price_cents: 1500,
          currency: "EUR",
          active: true,
          stock_quantity: 10,
          badges: []
        )

        @order = Order.create!(
          status: "pending_payment",
          payment_status: "pending",
          service_mode: "pickup",
          customer_email: "client@test.com",
          customer_phone: "0600000000",
          subtotal_cents: 3000,
          delivery_fee_cents: 0,
          total_cents: 3000
        )
        @order.order_items.create!(
          product: @product,
          name: @product.name,
          quantity: 2,
          unit_price_cents: 1500,
          line_total_cents: 3000,
          options: {}
        )

        @second_order = Order.create!(
          status: "pending_payment",
          payment_status: "pending",
          service_mode: "pickup",
          customer_email: "client2@test.com",
          customer_phone: "0600000001",
          subtotal_cents: 1500,
          delivery_fee_cents: 0,
          total_cents: 1500
        )
        @second_order.order_items.create!(
          product: @product,
          name: @product.name,
          quantity: 1,
          unit_price_cents: 1500,
          line_total_cents: 1500,
          options: {}
        )

        Rails.cache.clear
      end

      teardown do
        Rails.cache.clear
      end

      test "create checkout session persists pending payment" do
        fake_session = OpenStruct.new(id: "cs_test_1", url: "https://checkout.test/session")

        Stripe::Checkout::Session.stub(:create, fake_session) do
          post "/api/v1/payments/session",
               params: {
                 order: {
                   order_id: @order.id,
                   success_url: "https://example.com/success",
                   cancel_url: "https://example.com/cancel"
                 }
               },
               headers: { "Idempotency-Key" => "idem-pay-1" }
        end

        assert_response :created
        body = response.parsed_body
        assert_equal @order.id.to_s, body["order_id"]
        assert_equal "cs_test_1", body["checkout_session_id"]
        assert_equal 1, @order.payments.count
        assert_equal "pending", @order.payments.last.status
      end

      test "idempotency returns cached response for same payload" do
        fake_session = OpenStruct.new(id: "cs_test_cached", url: "https://checkout.test/cached")
        stripe_calls = 0

        Stripe::Checkout::Session.stub(:create, ->(*_args) {
          stripe_calls += 1
          fake_session
        }) do
          Stripe::Checkout::Session.stub(:retrieve, fake_session) do
            2.times do
              post "/api/v1/payments/session",
                   params: {
                     order: {
                       order_id: @order.id,
                       success_url: "https://example.com/success",
                       cancel_url: "https://example.com/cancel"
                     }
                   },
                   headers: { "Idempotency-Key" => "idem-cache-1" }
              assert_response :created
            end
          end
        end

        assert_equal 1, stripe_calls
        assert_equal 1, @order.payments.count
      end

      test "idempotency key cannot be reused with different payload" do
        fake_session = OpenStruct.new(id: "cs_test_conflict", url: "https://checkout.test/conflict")

        Stripe::Checkout::Session.stub(:create, fake_session) do
          post "/api/v1/payments/session",
               params: {
                 order: {
                   order_id: @order.id,
                   success_url: "https://example.com/success",
                   cancel_url: "https://example.com/cancel"
                 }
               },
               headers: { "Idempotency-Key" => "idem-conflict-1" }
          assert_response :created
        end

        post "/api/v1/payments/session",
             params: {
               order: {
                 order_id: @second_order.id,
                 success_url: "https://example.com/success",
                 cancel_url: "https://example.com/cancel"
               }
             },
             headers: { "Idempotency-Key" => "idem-conflict-1" }

        assert_response :unprocessable_entity
        assert_equal "validation_error", response.parsed_body.dig("error", "code")
        assert_equal "already_used_for_another_order", response.parsed_body.dig("error", "details", "idempotency_key")
      end

      test "retry creates a new checkout session for existing order" do
        fake_session = OpenStruct.new(id: "cs_test_retry", url: "https://checkout.test/retry")

        Stripe::Checkout::Session.stub(:create, fake_session) do
          post "/api/v1/payments/#{@order.id}/retry",
               params: {
                 order: {
                   success_url: "https://example.com/success",
                   cancel_url: "https://example.com/cancel"
                 }
               }
        end

        assert_response :created
        assert_equal "cs_test_retry", response.parsed_body["checkout_session_id"]
      end

      test "create session rejects order already paid" do
        @order.update!(payment_status: "paid", status: "confirmed")

        post "/api/v1/payments/session",
             params: {
               order: {
                 order_id: @order.id,
                 success_url: "https://example.com/success",
                 cancel_url: "https://example.com/cancel"
               }
             }

        assert_response :unprocessable_entity
        assert_equal "validation_error", response.parsed_body.dig("error", "code")
        assert_equal "must be pending_payment", response.parsed_body.dig("error", "details", "order")
        assert_equal "must be pending or failed", response.parsed_body.dig("error", "details", "payment_status")
      end

      test "retry rejects order already paid" do
        @order.update!(payment_status: "paid", status: "confirmed")

        post "/api/v1/payments/#{@order.id}/retry",
             params: {
               order: {
                 success_url: "https://example.com/success",
                 cancel_url: "https://example.com/cancel"
               }
             }

        assert_response :unprocessable_entity
        assert_equal "validation_error", response.parsed_body.dig("error", "code")
        assert_equal "must be pending_payment", response.parsed_body.dig("error", "details", "order")
        assert_equal "must be pending or failed", response.parsed_body.dig("error", "details", "payment_status")
      end
    end
  end
end
