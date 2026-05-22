require "test_helper"

module Delivery
  class PricingTest < ActiveSupport::TestCase
    test "uses configured tier values" do
      settings = BusinessSetting.current
      settings.update!(
        tier_one_max_km: 7,
        tier_one_fee_cents: 700,
        tier_two_max_km: 15,
        tier_two_fee_cents: 1300
      )

      assert_equal 700, Pricing.fee_cents_for(5)
      assert_equal 1300, Pricing.fee_cents_for(12)
      assert_nil Pricing.fee_cents_for(16)
      assert_equal 700, Pricing.default_fee_cents
      assert_equal 15.0, Pricing.max_distance_km
    end
  end
end
