class ProductPriceChange < ApplicationRecord
  belongs_to :product

  validates :old_price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :new_price_cents, numericality: { greater_than_or_equal_to: 0 }
end
