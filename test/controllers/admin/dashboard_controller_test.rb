require "test_helper"

module Admin
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = User.create!(
        email: "nl.cuisinent@gmail.com",
        password: "password123",
        role: "admin"
      )

      login_as_admin
    end

    test "dashboard supports quick period selection" do
      get admin_dashboard_path, params: { period_days: 7 }

      assert_response :success
      assert_includes response.body, "Vue d'ensemble"
      assert_includes response.body, "Commandes du jour"
    end

    test "dashboard accepts explicit date range" do
      get admin_dashboard_path, params: {
        date_from: 2.days.ago.to_date.to_s,
        date_to: Date.current.to_s
      }

      assert_response :success
      assert_includes response.body, "Vue d'ensemble"
    end

    private

    def login_as_admin
      post "/auth/login", params: {
        email: @admin.email,
        password: "password123"
      }
      follow_redirect!
    end
  end
end
