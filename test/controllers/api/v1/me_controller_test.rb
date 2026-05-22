require "test_helper"

module Api
  module V1
    class MeControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = User.create!(
          email: "account@test.com",
          full_name: "Compte Client",
          phone: "0600000000",
          role: "customer",
          active: true
        )
        @token = @user.api_token
      end

      test "show requires auth token" do
        get "/api/v1/me"

        assert_response :unauthorized
      end

      test "show returns current user" do
        get "/api/v1/me", headers: { "X-Customer-Token" => @token }

        assert_response :ok
        assert_equal @user.email, response.parsed_body.dig("data", "email")
      end

      test "update profile" do
        patch "/api/v1/me",
              params: {
                user: {
                  full_name: "Nouveau Nom"
                }
              },
              headers: { "X-Customer-Token" => @token }

        assert_response :ok
        assert_equal "Nouveau Nom", response.parsed_body.dig("data", "full_name")
      end

      test "destroy deactivates account and rotates token" do
        previous_token = @token

        delete "/api/v1/me", headers: { "X-Customer-Token" => previous_token }

        assert_response :no_content
        @user.reload
        assert_not @user.active
        assert_not_equal previous_token, @user.api_token
      end
    end
  end
end
