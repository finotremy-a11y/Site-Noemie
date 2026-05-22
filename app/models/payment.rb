class Payment < ApplicationRecord
  PROVIDERS = %w[stripe cash].freeze
  STATUSES = %w[pending paid failed refunded].freeze

  belongs_to :order
  has_many :payment_events, dependent: :destroy

  validates :provider, inclusion: { in: PROVIDERS }
  validates :status, inclusion: { in: STATUSES }
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :idempotency_key, uniqueness: { scope: :provider }, allow_nil: true
end
