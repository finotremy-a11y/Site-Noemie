require "test_helper"

module Api
  module V1
    module Auth
      class SessionsControllerTest < ActionDispatch::IntegrationTest
        test "create session creates customer token" do
          post "/api/v1/auth/session",
               params: {
                 user: {
                   email: "client@example.com",
                   full_name: "Client Test",
                   phone: "0601020304"
                 }
               }

          assert_response :created
          token = response.parsed_body.dig("data", "token")
          assert token.present?

          user = User.find_by(email: "client@example.com")
          assert_not_nil user
          assert_equal token, user.api_token
        end

        test "create session validates email" do
          post "/api/v1/auth/session", params: { user: { email: "" } }

          assert_response :unprocessable_entity
          assert_equal "validation_error", response.parsed_body.dig("error", "code")
        end
      end
    end
  end
end
