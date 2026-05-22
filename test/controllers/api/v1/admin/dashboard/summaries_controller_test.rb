require "test_helper"

module Api
  module V1
    module Admin
      module Dashboard
        class SummariesControllerTest < ActionDispatch::IntegrationTest
          setup do
            @previous_token = ENV["ADMIN_API_TOKEN"]
            ENV["ADMIN_API_TOKEN"] = "test_admin_token"

            @admin = User.create!(email: "dashboard-admin@example.com", role: "admin", active: true)
            @admin.generate_api_token
            @admin.save!

            travel_to Time.zone.parse("2026-03-31 12:00:00")

            Order.create!(
              status: "pending_payment",
              payment_status: "pending",
              service_mode: "pickup",
              customer_email: "pending@test.com",
              customer_phone: "0600000001",
              subtotal_cents: 2000,
              delivery_fee_cents: 0,
              total_cents: 2000
            )

            Order.create!(
              status: "confirmed",
              payment_status: "paid",
              service_mode: "delivery",
              customer_email: "paid@test.com",
              customer_phone: "0600000002",
              subtotal_cents: 3000,
              delivery_fee_cents: 400,
              total_cents: 3400
            )

            Quote.create!(
              email: "quote@test.com",
              status: "new",
              event_date: 1.month.from_now
            )

            Review.create!(
              rating: 4,
              status: "pending"
            )
          end

          teardown do
            travel_back
            ENV["ADMIN_API_TOKEN"] = @previous_token
          end

          test "show returns dashboard summary" do
            get "/api/v1/admin/dashboard/summary", headers: admin_headers

            assert_response :ok
            body = response.parsed_body
            assert_equal 2, body.dig("data", "kpis", "orders_today")
            assert_equal 3400, body.dig("data", "kpis", "revenue_today_cents")
            assert_equal 1, body.dig("data", "operations", "pending_orders")
            assert_equal 1, body.dig("data", "operations", "pending_quotes")
            assert_equal 1, body.dig("data", "operations", "pending_reviews")
          end

          test "show accepts period and date range parameters" do
            get "/api/v1/admin/dashboard/summary",
                params: {
                  period_days: 7,
                  date_from: 2.days.ago.to_date.to_s,
                  date_to: Date.current.to_s
                },
                headers: admin_headers

            assert_response :ok
            body = response.parsed_body
            assert body.dig("data", "range", "from").present?
            assert body.dig("data", "range", "to").present?
            assert body.dig("data", "kpis", "conversion_rate_period").is_a?(Numeric)
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
end
