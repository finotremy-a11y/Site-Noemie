class Product < ApplicationRecord
  belongs_to :category
  has_many :product_options, dependent: :destroy
  has_many :product_price_changes, dependent: :destroy

  validates :name, presence: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :in_season, lambda {
    today = Time.zone.today
    where("(seasonal_start_date IS NULL OR seasonal_start_date <= ?) AND (seasonal_end_date IS NULL OR seasonal_end_date >= ?)", today, today)
  }
  scope :available, -> { where(active: true).where("stock_quantity > 0") }

  def available?
    active? && stock_quantity.to_i.positive?
  end

  def options?
    product_options.active.exists?
  end

  def price
    price_cents.to_i / 100.0
  end

  def is_available
    available?
  end

  def sku
    "P-#{id.to_s.rjust(5, '0')}"
  end
end
