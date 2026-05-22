class PaymentEvent < ApplicationRecord
  belongs_to :payment, optional: true

  validates :event_type, presence: true
end
