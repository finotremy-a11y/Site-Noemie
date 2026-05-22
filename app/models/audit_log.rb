class AuditLog < ApplicationRecord
  ACTIONS = %w[create update destroy quote_status_changed review_status_changed].freeze

  belongs_to :user, optional: true

  validates :action, presence: true
  validates :resource_type, presence: true
  validates :resource_id, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_resource, ->(type, id) { where(resource_type: type, resource_id: id) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :for_action, ->(action) { where(action: action) }

  def display_action
    I18n.t("audit_log.action.#{action}", default: action)
  end
end
