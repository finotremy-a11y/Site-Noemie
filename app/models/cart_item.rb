class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price_cents, numericality: { greater_than_or_equal_to: 0 }

  before_validation :sync_unit_price_from_product, if: -> { product.present? }

  def line_total_cents
    quantity * unit_price_cents
  end

  def unit_price
    unit_price_cents.to_i / 100.0
  end

  def total_price
    line_total_cents.to_i / 100.0
  end

  def special_instructions
    options["special_instructions"].presence
  end

  private

  def sync_unit_price_from_product
    self.unit_price_cents = product.price_cents
  end
end
