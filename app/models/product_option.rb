class ProductOption < ApplicationRecord
  belongs_to :product

  validates :name, presence: true
  validates :price_delta_cents, numericality: true

  scope :active, -> { where(active: true) }
end
