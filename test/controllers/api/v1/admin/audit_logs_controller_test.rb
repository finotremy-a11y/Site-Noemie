require "test_helper"

module Api
  module V1
    module Admin
      class AuditLogsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @previous_admin_token = ENV["ADMIN_API_TOKEN"]
          ENV["ADMIN_API_TOKEN"] = "test_admin_token"

          @admin = User.create!(email: "nl.cuisinent@gmail.com", role: "admin", active: true)
          @admin.generate_api_token
          @admin.save!
          @token = @admin.api_token

          @customer = User.create!(email: "customer@example.com", role: "customer", active: true)
          @order = @customer.orders.create!(
            order_number: "ORD-001",
            status: "pending_payment",
            payment_status: "pending",
            service_mode: "delivery",
            subtotal_cents: 1000,
            delivery_fee_cents: 0,
            total_cents: 1000
          )

          AuditLog.create!(
            user_id: @customer.id,
            action: :create,
            resource_type: "Order",
            resource_id: @order.id,
            metadata: { status: "pending_payment" }
          )
        end

        teardown do
          ENV["ADMIN_API_TOKEN"] = @previous_admin_token
        end

        test "index returns audit logs for admin" do
          get "/api/v1/admin/audit_logs", headers: {
            "X-Admin-Token" => "test_admin_token",
            "X-Customer-Token" => @token
          }
          assert_response :success

          json = JSON.parse(response.body)
          assert json["data"].is_a?(Array)
          assert json["pagination"]
        end

        test "index filters by resource type and id" do
          get "/api/v1/admin/audit_logs",
              params: { resource_type: "Order", resource_id: @order.id },
              headers: {
                "X-Admin-Token" => "test_admin_token",
                "X-Customer-Token" => @token
              }

          assert_response :success
          json = JSON.parse(response.body)
          assert_equal 1, json["data"].length
          assert_equal "Order", json.dig("data", 0, "resource_type")
        end

        test "show returns a single audit log" do
          log = AuditLog.first
          get "/api/v1/admin/audit_logs/#{log.id}", headers: {
            "X-Admin-Token" => "test_admin_token",
            "X-Customer-Token" => @token
          }
          assert_response :success

          json = JSON.parse(response.body)
          assert_equal log.display_action, json.dig("data", "action")
        end

        test "requires admin role" do
          customer = User.create!(email: "user@example.com", role: "customer", active: true)
          customer.generate_api_token
          customer.save!

          get "/api/v1/admin/audit_logs", headers: {
            "X-Admin-Token" => "test_admin_token",
            "X-Customer-Token" => customer.api_token
          }
          assert_response :forbidden
        end
      end
    end
  end
end
