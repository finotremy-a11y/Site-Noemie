class Review < ApplicationRecord
  STATUSES = %w[pending approved rejected hidden].freeze

  belongs_to :user, optional: true
  belongs_to :order, optional: true

  validates :rating, inclusion: { in: 1..5 }
  validates :status, inclusion: { in: STATUSES }

  scope :approved, -> { where(status: "approved") }
end
