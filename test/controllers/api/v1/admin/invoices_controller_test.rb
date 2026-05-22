require "test_helper"

module Api
  module V1
    module Admin
      class InvoicesControllerTest < ActionDispatch::IntegrationTest
        setup do
          @previous_token = ENV["ADMIN_API_TOKEN"]
          ENV["ADMIN_API_TOKEN"] = "test_admin_token"

          @admin = User.create!(email: "invoices-admin@example.com", role: "admin", active: true)
          @admin.generate_api_token
          @admin.save!

          @order = Order.create!(
            status: "confirmed",
            payment_status: "paid",
            service_mode: "pickup",
            customer_email: "client@test.com",
            customer_phone: "0600000000",
            subtotal_cents: 2200,
            delivery_fee_cents: 0,
            total_cents: 2200
          )
          @invoice = Invoice.create!(
            order: @order,
            invoice_number: "INV-202603-00001",
            total_cents: 2200,
            status: "issued",
            issued_at: Time.current
          )
        end

        teardown do
          ENV["ADMIN_API_TOKEN"] = @previous_token
        end

        test "index returns invoices" do
          get "/api/v1/admin/invoices", headers: admin_headers

          assert_response :ok
          assert_equal 1, response.parsed_body.fetch("data").size
        end

        test "show returns invoice" do
          get "/api/v1/admin/invoices/#{@invoice.id}", headers: admin_headers

          assert_response :ok
          assert_equal @invoice.invoice_number, response.parsed_body.dig("data", "invoice_number")
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
