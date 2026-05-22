class Quote < ApplicationRecord
  STATUSES = %w[new in_progress processed rejected].freeze

  belongs_to :user, optional: true

  validates :email, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :event_date_must_be_in_future, if: -> { event_date.present? }

  private

  def event_date_must_be_in_future
    return if event_date.future?

    errors.add(:event_date, "must be in the future")
  end
end
