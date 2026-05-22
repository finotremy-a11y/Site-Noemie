require "test_helper"

module Api
  module V1
    class ContactsControllerTest < ActionDispatch::IntegrationTest
      include ActiveJob::TestHelper

      setup do
        ActiveJob::Base.queue_adapter = :test
      end

      test "create contact request" do
        assert_enqueued_with(job: Notifications::InquiryNotificationJob) do
          post "/api/v1/contact",
               params: {
                 contact: {
                   name: "Noemie",
                   email: "noemie@example.com",
                   message: "Bonjour, je souhaite une information"
                 }
               }
        end

        assert_response :created
        assert_equal "received", response.parsed_body.dig("data", "status")
      end

      test "create contact validates fields" do
        post "/api/v1/contact", params: { contact: { name: "", email: "", message: "" } }

        assert_response :unprocessable_entity
        assert_equal "validation_error", response.parsed_body.dig("error", "code")
      end
    end
  end
end
