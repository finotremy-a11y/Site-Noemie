require "test_helper"

module Api
  module V1
    class QuotesControllerTest < ActionDispatch::IntegrationTest
      include ActiveJob::TestHelper

      setup do
        ActiveJob::Base.queue_adapter = :test
      end

      test "create quote with valid payload" do
        assert_enqueued_with(job: Notifications::InquiryNotificationJob) do
          post "/api/v1/quotes",
               params: {
                 quote: {
                   email: "client@example.com",
                   phone: "0600000000",
                   event_type: "entreprise",
                   guest_count: 60,
                   event_date: 1.month.from_now,
                   location: "Lyon",
                   budget_cents: 150_000,
                   constraints: "Sans arachides",
                   message: "Cocktail dejeunatoire"
                 }
               }
        end

        assert_response :created
        assert_equal "new", response.parsed_body.dig("data", "status")
      end

      test "create quote rejects past date" do
        post "/api/v1/quotes",
             params: {
               quote: {
                 email: "client@example.com",
                 event_date: 1.day.ago
               }
             }

        assert_response :unprocessable_entity
        assert_equal "validation_error", response.parsed_body.dig("error", "code")
      end
    end
  end
end
