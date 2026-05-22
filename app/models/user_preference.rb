class UserPreference < ApplicationRecord
  LANGUAGES = %w[fr].freeze
  NOTIFICATION_TYPES = %w[email_order email_quote email_promotional].freeze

  belongs_to :user

  validates :user_id, :language, presence: true
  validates :language, inclusion: { in: LANGUAGES }

  before_validation :force_french
  before_create :set_defaults

  def notifications_enabled?(type)
    return false unless NOTIFICATION_TYPES.include?(type)

    send("notifications_#{type}") != false
  end

  private

  def force_french
    self.language = "fr"
  end

  def set_defaults
    self.language ||= "fr"
    self.notifications_email_order = true if notifications_email_order.nil?
    self.notifications_email_quote = true if notifications_email_quote.nil?
    self.notifications_email_promotional = false if notifications_email_promotional.nil?
  end
end
