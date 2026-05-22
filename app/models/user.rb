class User < ApplicationRecord
  ROLES = %w[customer admin].freeze

  has_secure_password validations: false
  has_secure_token :api_token

  has_many :orders, dependent: :nullify
  has_many :carts, dependent: :nullify
  has_many :quotes, dependent: :nullify
  has_many :reviews, dependent: :nullify
  has_many :addresses, dependent: :destroy
  has_one :user_preference, dependent: :destroy

  before_validation :normalize_email
  after_create :create_default_preference

  validates :email, presence: true, uniqueness: true
  validates :api_token, uniqueness: true, allow_nil: true
  validates :role, inclusion: { in: ROLES }

  # Accès au panier actif (non converti)
  def current_cart
    carts.where(status: "open").order(updated_at: :desc).first
  end

  def find_or_create_cart
    current_cart || carts.create!(status: "open")
  end

  def delivery_address
    addresses.where(address_type: "delivery").find_by(is_default: true) ||
      addresses.where(address_type: "delivery").first
  end

  def billing_address
    addresses.where(address_type: "billing").find_by(is_default: true) ||
      addresses.where(address_type: "billing").first
  end

  # Alias pour compatibilité controllers
  def preferences
    user_preference || create_user_preference
  end

  def preference
    preferences
  end

  def build_preferences
    build_user_preference
  end

  def build_preference
    build_preferences
  end

  def admin?
    role == "admin"
  end

  def customer?
    role == "customer"
  end

  # Compatibilité avec tests/anciens appels.
  def generate_api_token
    regenerate_api_token
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def create_default_preference
    UserPreference.create(user_id: id) unless user_preference
  end
end
