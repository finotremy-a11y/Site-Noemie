class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product, optional: true

  validates :name, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price_cents, :line_total_cents, numericality: { greater_than_or_equal_to: 0 }

  before_validation :compute_line_total

  private

  def compute_line_total
    self.line_total_cents = quantity.to_i * unit_price_cents.to_i
  end
end
