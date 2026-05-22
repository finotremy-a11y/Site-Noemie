module Delivery
  class Pricing
    def self.config
      BusinessSetting.current
    end

    def self.default_fee_cents
      config.tier_one_fee_cents
    end

    def self.max_distance_km
      config.tier_two_max_km.to_f
    end

    def self.fee_cents_for(distance_km)
      distance = distance_km.to_f
      return nil if distance <= 0
      return config.tier_one_fee_cents if distance <= config.tier_one_max_km.to_f
      return config.tier_two_fee_cents if distance <= config.tier_two_max_km.to_f

      nil
    end

    def self.allowed?(distance_km)
      !fee_cents_for(distance_km).nil?
    end
  end
end
