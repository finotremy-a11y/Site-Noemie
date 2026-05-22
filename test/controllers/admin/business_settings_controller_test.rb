require "test_helper"

module Admin
  class BusinessSettingsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = User.create!(
        email: "settings-admin@example.com",
        password: "password123",
        role: "admin",
        active: true
      )

      login_as_admin
    end

    test "show is accessible for admin" do
      get admin_business_settings_path

      assert_response :success
      assert_includes response.body, "Parametres metier"
    end

    test "update persists configurable delivery rules" do
      patch admin_business_settings_path, params: {
        business_setting: {
          delivery_min_order_cents: 3000,
          tier_one_max_km: 8,
          tier_one_fee_cents: 600,
          tier_two_max_km: 18,
          tier_two_fee_cents: 1200,
          vat_rate: 0.2
        }
      }

      assert_redirected_to admin_business_settings_path
      settings = BusinessSetting.current
      assert_equal 3000, settings.delivery_min_order_cents
      assert_equal 8.0, settings.tier_one_max_km.to_f
      assert_equal 600, settings.tier_one_fee_cents
      assert_equal 18.0, settings.tier_two_max_km.to_f
      assert_equal 1200, settings.tier_two_fee_cents
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
