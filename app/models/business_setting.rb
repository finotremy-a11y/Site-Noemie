class BusinessSetting < ApplicationRecord
  validates :delivery_min_order_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :tier_one_max_km, numericality: { greater_than: 0 }
  validates :tier_one_fee_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :tier_two_max_km, numericality: { greater_than: 0 }
  validates :tier_two_fee_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :vat_rate, numericality: { greater_than_or_equal_to: 0, less_than: 1 }
  validate :tier_order_consistency

  def self.current
    first_or_create!
  end

  private

  def tier_order_consistency
    return if tier_two_max_km.to_f > tier_one_max_km.to_f

    errors.add(:tier_two_max_km, "must be greater than tier one max km")
  end
end
