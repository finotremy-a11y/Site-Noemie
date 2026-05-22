require "test_helper"

module Api
  module V1
    module Admin
      class QuotesControllerTest < ActionDispatch::IntegrationTest
        include ActiveJob::TestHelper

        setup do
          ActiveJob::Base.queue_adapter = :test
          @previous_token = ENV["ADMIN_API_TOKEN"]
          ENV["ADMIN_API_TOKEN"] = "test_admin_token"

          @admin = User.create!(email: "quotes-admin@example.com", role: "admin", active: true)
          @admin.generate_api_token
          @admin.save!

          @quote = Quote.create!(
            email: "client@example.com",
            phone: "0600000000",
            event_type: "festival",
            guest_count: 120,
            event_date: 2.months.from_now,
            location: "Paris",
            budget_cents: 220_000,
            message: "Evenement de lancement"
          )
        end

        teardown do
          ENV["ADMIN_API_TOKEN"] = @previous_token
        end

        test "index requires admin token" do
          get "/api/v1/admin/quotes"

          assert_response :forbidden
        end

        test "index returns quotes with admin token" do
          get "/api/v1/admin/quotes", headers: admin_headers

          assert_response :ok
          assert_equal 1, response.parsed_body.fetch("data").size
        end

        test "update quote status" do
          assert_enqueued_with(job: Notifications::CustomerNotificationJob) do
            patch "/api/v1/admin/quotes/#{@quote.id}/status",
                  params: {
                    quote: { status: "in_progress" }
                  },
                  headers: admin_headers
          end

          assert_response :ok
          @quote.reload
          assert_equal "in_progress", @quote.status
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
