class Address < ApplicationRecord
  TYPES = %w[delivery billing].freeze

  belongs_to :user

  validates :user_id, :full_name, :street, :city, :postal_code, :country, :phone, presence: true
  validates :address_type, inclusion: { in: TYPES }
  validates :is_default, inclusion: { in: [ true, false ] }

  before_save :clear_other_defaults, if: :is_default_changed?

  scope :delivery, -> { where(address_type: "delivery") }
  scope :billing, -> { where(address_type: "billing") }
  scope :default_for, ->(type) { where(address_type: type, is_default: true).first }

  private

  def clear_other_defaults
    return unless is_default

    Address.where(user_id: user_id, address_type: address_type)
           .where.not(id: id)
           .update_all(is_default: false)
  end
end
