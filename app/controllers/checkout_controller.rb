class CheckoutController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :success, :cancel, :retry_payment ]

  def show
    @business_setting = BusinessSetting.current

    if current_user
      @cart = current_user.current_cart || current_user.find_or_create_cart
    elsif session[:cart_session_token]
      @cart = Cart.find_by(session_token: session[:cart_session_token])
    end

    @cart ||= Cart.new
    @cart_items = @cart.persisted? ? @cart.cart_items.includes(:product) : []

    unless @cart_items.any?
      redirect_to catalog_path, alert: "Votre panier est vide"
      nil
    end
  end

  def create
    @cart = current_user.current_cart
    payment_method = params[:payment_method].to_s.presence || "stripe"

    unless @cart&.cart_items&.any?
      redirect_to cart_path, alert: "Votre panier est vide"
      return
    end

    if params[:delivery_mode].blank?
      flash.now[:alert] = "Veuillez sélectionner un mode de livraison"
      @cart_items = @cart.cart_items.includes(:product)
      render :show, status: :unprocessable_entity
      return
    end

    selected_address = current_user.addresses.find_by(id: params[:address_id])
    delivery_address = if params[:delivery_mode] == "delivery" && selected_address.present?
      [ selected_address.full_name, selected_address.street, "#{selected_address.postal_code} #{selected_address.city}", selected_address.country ].compact.join(", ")
    end

    order = Orders::CreateFromCart.new(
      cart: @cart,
      attrs: {
        "service_mode" => params[:delivery_mode],
        "customer_email" => current_user.email,
        "customer_phone" => current_user.phone,
        "delivery_address" => delivery_address,
        "delivery_distance_km" => params[:delivery_distance_km],
        "special_instructions" => params[:special_instructions]
      }
    ).call

    unless order.persisted?
      flash.now[:alert] = "Erreur lors de la création de la commande"
      @cart_items = @cart.cart_items.includes(:product)
      render :show, status: :unprocessable_entity
      return
    end

    if payment_method == "cash"
      order.update!(status: "pending_validation", payment_status: "pending")
      order.payments.create!(
        provider: "cash",
        status: "pending",
        amount_cents: order.total_cents,
        currency: "EUR"
      )
      Notifications::SendOrderConfirmationEmailJob.perform_later(order.id)
      redirect_to order_success_path(order), notice: "Commande en attente de validation. Paiement en especes a la remise."
      return
    end

    checkout_session = Payments::CreateCheckoutSession.new(
      payload: {
        "order_id" => order.id,
        "customer_email" => current_user.email,
        "success_url" => order_success_url(order),
        "cancel_url" => order_cancel_url(order)
      }
    ).call

    redirect_to checkout_session[:checkout_url], allow_other_host: true
  rescue Orders::CreateFromCart::ValidationError, Payments::CreateCheckoutSession::ValidationError => error
    flash.now[:alert] = error.details.values.join(", ")
    @cart_items = @cart&.cart_items&.includes(:product) || []
    render :show, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => error
    flash.now[:alert] = error.record.errors.full_messages.join(", ")
    @cart_items = @cart&.cart_items&.includes(:product) || []
    render :show, status: :unprocessable_entity
  end

  def success
    # Le statut est mis à jour par le webhook Stripe — on affiche juste la confirmation
    @order = current_user.orders.find_by(id: params[:id])
  end

  def cancel
    @order = current_user.orders.find_by(id: params[:id])
  end

  def retry_payment
    order = current_user.orders.find(params[:id])
    checkout_session = Payments::CreateCheckoutSession.new(
      payload: {
        "order_id" => order.id,
        "customer_email" => current_user.email,
        "success_url" => order_success_url(order),
        "cancel_url" => order_cancel_url(order)
      }
    ).call

    redirect_to checkout_session[:checkout_url], allow_other_host: true
  rescue Payments::CreateCheckoutSession::ValidationError => error
    redirect_to me_order_path(order), alert: error.details.values.join(", ")
  end
end
