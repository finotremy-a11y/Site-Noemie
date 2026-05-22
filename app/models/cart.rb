class Cart < ApplicationRecord
  STATUSES = %w[open converted abandoned].freeze
  VAT_RATE = 0.20

  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }

  scope :open_state, -> { where(status: "open") }

  def subtotal_cents
    cart_items.sum("quantity * unit_price_cents")
  end

  def subtotal
    subtotal_cents / 100.0
  end

  def vat_cents(service_mode = "pickup")
    ((subtotal_cents + delivery_fee_cents(service_mode)) * VAT_RATE).round
  end

  def vat(service_mode = "pickup")
    vat_cents(service_mode) / 100.0
  end

  def delivery_fee_cents(service_mode)
    service_mode == "delivery" ? Delivery::Pricing.default_fee_cents : 0
  end

  def delivery_fee(service_mode = "pickup")
    delivery_fee_cents(service_mode) / 100.0
  end

  def discount_amount
    0.0
  end

  def total_cents(service_mode = "pickup")
    subtotal_cents + delivery_fee_cents(service_mode) + vat_cents(service_mode)
  end

  def total(service_mode = "pickup")
    total_cents(service_mode) / 100.0
  end
end
