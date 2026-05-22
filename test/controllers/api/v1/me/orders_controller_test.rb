require "test_helper"

module Api
  module V1
    module Me
      class OrdersControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = User.create!(
            email: "orders@test.com",
            full_name: "Client Orders",
            phone: "0600000000",
            role: "customer",
            active: true
          )
          @token = @user.api_token

          @order = Order.create!(
            user: @user,
            status: "pending_payment",
            payment_status: "pending",
            service_mode: "pickup",
            customer_email: @user.email,
            customer_phone: @user.phone,
            subtotal_cents: 1800,
            delivery_fee_cents: 0,
            total_cents: 1800
          )

          @order.order_items.create!(
            name: "Burger Test",
            quantity: 2,
            unit_price_cents: 900,
            line_total_cents: 1800,
            options: {}
          )
        end

        test "index requires auth" do
          get "/api/v1/me/orders"

          assert_response :unauthorized
        end

        test "index lists current user orders" do
          get "/api/v1/me/orders", headers: { "X-Customer-Token" => @token }

          assert_response :ok
          assert_equal 1, response.parsed_body.fetch("data").size
        end

        test "show returns detailed order" do
          get "/api/v1/me/orders/#{@order.id}", headers: { "X-Customer-Token" => @token }

          assert_response :ok
          assert_equal 1, response.parsed_body.dig("data", "items").size
        end
      end
    end
  end
end
