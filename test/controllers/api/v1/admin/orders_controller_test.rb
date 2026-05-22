require "test_helper"

module Api
  module V1
    module Admin
      class OrdersControllerTest < ActionDispatch::IntegrationTest
        setup do
          @previous_token = ENV["ADMIN_API_TOKEN"]
          ENV["ADMIN_API_TOKEN"] = "test_admin_token"

          @admin = User.create!(email: "orders-admin@example.com", role: "admin", active: true)
          @admin.generate_api_token
          @admin.save!

          @order = Order.create!(
            status: "pending_payment",
            payment_status: "pending",
            service_mode: "pickup",
            customer_email: "client@test.com",
            customer_phone: "0600000000",
            subtotal_cents: 2600,
            delivery_fee_cents: 0,
            total_cents: 2600
          )
        end

        teardown do
          ENV["ADMIN_API_TOKEN"] = @previous_token
        end

        test "index lists orders with admin token" do
          get "/api/v1/admin/orders", headers: admin_headers

          assert_response :ok
          assert_operator response.parsed_body.fetch("data").size, :>=, 1
        end

        test "status transition refuses confirm before payment" do
          patch "/api/v1/admin/orders/#{@order.id}/status",
                params: {
                  order: { status: "confirmed" }
                },
                headers: admin_headers

          assert_response :conflict
          assert_equal "status_conflict", response.parsed_body.dig("error", "code")
        end

        test "status transition accepts cancel with reason" do
          patch "/api/v1/admin/orders/#{@order.id}/status",
                params: {
                  order: {
                    status: "cancelled",
                    reason: "Client indisponible"
                  }
                },
                headers: admin_headers

          assert_response :ok
          @order.reload
          assert_equal "cancelled", @order.status
          assert_equal 1, AuditLog.where(resource_type: "Order", resource_id: @order.id).count
        end

        private

        def admin_headers
          {
            "X-Admin-Token" => "test_admin_token",
            "X-Customer-Token" => @admin.api_token
          }
        end
      end
    end
  end
end
