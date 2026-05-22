require "test_helper"

module Api
  module V1
    module Me
      class PreferencesControllerTest < ActionDispatch::IntegrationTest
        setup do
          @user = User.create!(email: "prefs@example.com", role: "customer", active: true)
          @user.generate_api_token
          @user.save!
          @token = @user.api_token
        end

        test "show user preferences" do
          get "/api/v1/me/preferences", headers: { "X-Customer-Token" => @token }
          assert_response :success

          json = JSON.parse(response.body)
          assert_equal "fr", json.dig("data", "language")
          assert json.dig("data", "notifications", "email_order")
        end

        test "show requires authentication" do
          get "/api/v1/me/preferences"
          assert_response :unauthorized
        end

        test "update preferences language" do
          patch "/api/v1/me/preferences",
                params: {
                  preferences: { language: "en" }
                },
                headers: { "X-Customer-Token" => @token }

          assert_response :success
          json = JSON.parse(response.body)
          assert_equal "en", json.dig("data", "language")
        end

        test "update notifications" do
          patch "/api/v1/me/preferences",
                params: {
                  preferences: {
                    notifications: {
                      email_order: false,
                      email_promotional: true
                    }
                  }
                },
                headers: { "X-Customer-Token" => @token }

          assert_response :success
          json = JSON.parse(response.body)
          refute json.dig("data", "notifications", "email_order")
          assert json.dig("data", "notifications", "email_promotional")
        end
      end
    end
  end
end
