class Order < ApplicationRecord
  STATUSES = %w[draft pending_payment pending_validation confirmed preparing ready completed cancelled].freeze
  ALLOWED_TRANSITIONS = {
    "draft" => %w[pending_payment cancelled],
    "pending_payment" => %w[pending_validation cancelled],
    "pending_validation" => %w[confirmed cancelled],
    "confirmed" => %w[preparing cancelled],
    "preparing" => %w[ready cancelled],
    "ready" => %w[completed cancelled],
    "completed" => [],
    "cancelled" => []
  }.freeze
  PAYMENT_STATUSES = %w[pending paid failed refunded].freeze
  SERVICE_MODES = %w[pickup delivery].freeze

  belongs_to :user, optional: true
  has_many :order_items, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_one :invoice, dependent: :destroy

  validates :order_number, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :payment_status, inclusion: { in: PAYMENT_STATUSES }
  validates :service_mode, inclusion: { in: SERVICE_MODES }

  before_validation :assign_order_number, on: :create

  def can_transition_to?(next_status)
    ALLOWED_TRANSITIONS.fetch(status, []).include?(next_status)
  end

  private

  def assign_order_number
    return if order_number.present?

    timestamp = Time.current.strftime("%Y%m%d%H%M%S")
    self.order_number = "NLC-#{timestamp}-#{SecureRandom.hex(2).upcase}"
  end
end
