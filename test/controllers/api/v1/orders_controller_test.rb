require "test_helper"

module Api
  module V1
    class OrdersControllerTest < ActionDispatch::IntegrationTest
      setup do
        @customer = User.create!(email: "api-orders-customer@example.com", role: "customer", active: true)
        @customer.generate_api_token
        @customer.save!

        @category = Category.find_or_create_by!(slug: "burgers-api-orders") do |category|
          category.name = "Burgers API Orders"
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

        @cart = Cart.create!(session_token: "order_cart_1", status: "open")
        @cart.cart_items.create!(product: @product, quantity: 2, unit_price_cents: 1500, options: {})

        @order = Order.create!(
          user: @customer,
          status: "pending_payment",
          payment_status: "pending",
          service_mode: "pickup",
          customer_email: @customer.email,
          customer_phone: "0600000000",
          subtotal_cents: 3000,
          delivery_fee_cents: 0,
          total_cents: 3600
        )
      end

      test "create order from cart" do
        post "/api/v1/orders",
             params: {
               order: {
                 service_mode: "pickup",
                 customer_email: "client@test.com",
                 customer_phone: "0600000000"
               }
             },
             headers: {
               "X-Cart-Token" => "order_cart_1",
               "Idempotency-Key" => "idem-order-1"
             }

        assert_response :created
        body = response.parsed_body
        assert_equal "pending_payment", body.dig("data", "status")
        assert_equal 3600, body.dig("data", "total_cents")
      end

      test "show requires authenticated customer" do
        get "/api/v1/orders/#{@order.id}"

        assert_response :unauthorized
      end

      test "status requires authenticated customer" do
        get "/api/v1/orders/#{@order.id}/status"

        assert_response :unauthorized
      end
    end
  end
end
