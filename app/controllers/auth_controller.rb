class AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :register, :login, :create, :show, :register_create, :logout ], raise: false

  def login
    @user = User.new
  end

  def register
    @user = User.new
  end

  def create
    email = params[:email]
    password = params[:password]

    user = User.find_by(email: email)

    if user && user.authenticate(password)
      sign_in_user!(user)
      redirect_to after_sign_in_path, notice: "Connexion réussie"
    else
      redirect_to login_path, alert: "Email ou mot de passe incorrect"
    end
  end

  def register_create
    email = params[:email]
    password = params[:password]
    password_confirmation = params[:password_confirmation]

    if password != password_confirmation
      redirect_to register_path, alert: "Les mots de passe ne correspondent pas"
      return
    end

    user = User.new(email: email, password: password)

    if user.save
      sign_in_user!(user)
      redirect_to after_sign_in_path, notice: "Inscription réussie"
    else
      redirect_to register_path, alert: user.errors.full_messages.join(", ")
    end
  end

  def logout
    session.delete(:session_token)
    session.delete(:user_id)
    session.delete(:return_to)
    session.delete(:cart_session_token)

    redirect_to root_path, notice: "Déconnexion réussie"
  end

  private

  def sign_in_user!(user)
    session[:session_token] = user.api_token
    session[:user_id] = user.id
    attach_guest_cart_to_user!(user)
  end

  def after_sign_in_path
    stored_location = session.delete(:return_to)
    stored_location.presence || me_path
  end

  def attach_guest_cart_to_user!(user)
    guest_cart = Cart.find_by(session_token: session[:cart_session_token])
    return unless guest_cart
    return if guest_cart.user_id == user.id

    user_cart = user.find_or_create_cart

    guest_cart.cart_items.find_each do |item|
      existing_item = user_cart.cart_items.find_by(product_id: item.product_id)
      if existing_item
        merged_options = existing_item.options.merge(item.options || {}).compact
        existing_item.update!(quantity: existing_item.quantity + item.quantity, options: merged_options)
      else
        user_cart.cart_items.create!(
          product: item.product,
          quantity: item.quantity,
          unit_price_cents: item.unit_price_cents,
          options: item.options || {}
        )
      end
    end

    Cart::Recalculate.new(cart: user_cart).call
    guest_cart.update!(status: "converted", user: user)
    session.delete(:cart_session_token)
  end
end
