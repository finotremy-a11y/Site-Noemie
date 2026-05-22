module Auditable
  extend ActiveSupport::Concern

  included do
    after_create :audit_create
    after_update :audit_update
    after_destroy :audit_destroy
  end

  private

  def audit_create
    AuditLog.create!(
      user_id: user_id_for_audit,
      action: :create,
      resource_type: self.class.name,
      resource_id: id,
      changes: attributes.except("created_at", "updated_at")
    )
  rescue StandardError => e
    Rails.logger.warn("Audit create failed for #{self.class.name}##{id}: #{e.message}")
  end

  def audit_update
    # Only audit if there are actual changes
    return if changes_to_audit.blank?

    AuditLog.create!(
      user_id: user_id_for_audit,
      action: :update,
      resource_type: self.class.name,
      resource_id: id,
      changes: changes_to_audit
    )
  rescue StandardError => e
    Rails.logger.warn("Audit update failed for #{self.class.name}##{id}: #{e.message}")
  end

  def audit_destroy
    AuditLog.create!(
      user_id: user_id_for_audit,
      action: :destroy,
      resource_type: self.class.name,
      resource_id: id,
      changes: attributes.except("created_at", "updated_at", "updated_at")
    )
  rescue StandardError => e
    Rails.logger.warn("Audit destroy failed for #{self.class.name}##{id}: #{e.message}")
  end

  def changes_to_audit
    changes.except("updated_at")
  end

  def user_id_for_audit
    # Can be overridden in subclasses
    respond_to?(:user_id) ? user_id : nil
  end
end
