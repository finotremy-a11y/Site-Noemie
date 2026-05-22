require "test_helper"

module Api
  module V1
    module Me
      class InvoicesControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = User.create!(email: "invoice@example.com", role: "customer", active: true)
          @user.generate_api_token
          @user.save!
          @token = @user.api_token

          @order = @user.orders.create!(
            order_number: "ORD-INV-001",
            status: "confirmed",
            payment_status: "paid",
            service_mode: "delivery",
            subtotal_cents: 5000,
            delivery_fee_cents: 500,
            total_cents: 5500
          )

          @invoice = @order.create_invoice!(
            invoice_number: "INV-#{SecureRandom.hex(4).upcase}",
            status: "issued",
            total_cents: 5500,
            issued_at: Time.current
          )
        end

        test "index returns user invoices" do
          get "/api/v1/me/invoices", headers: { "X-Customer-Token" => @token }
          assert_response :success

          json = JSON.parse(response.body)
          assert json["data"].is_a?(Array)
          assert_equal 1, json["data"].length
          assert_equal @invoice.invoice_number, json.dig("data", 0, "invoice_number")
        end

        test "show returns specific invoice" do
          get "/api/v1/me/invoices/#{@invoice.id}", headers: { "X-Customer-Token" => @token }
          assert_response :success

          json = JSON.parse(response.body)
          assert_equal @invoice.id, json.dig("data", "id")
          assert_equal "issued", json.dig("data", "status")
        end

        test "show returns not found for other user's invoice" do
          other_user = User.create!(email: "other@example.com", role: "customer", active: true)
          other_user.generate_api_token
          other_user.save!

          get "/api/v1/me/invoices/#{@invoice.id}", headers: { "X-Customer-Token" => other_user.api_token }
          assert_response :not_found
        end

        test "requires authentication" do
          get "/api/v1/me/invoices"
          assert_response :unauthorized
        end
      end
    end
  end
end
