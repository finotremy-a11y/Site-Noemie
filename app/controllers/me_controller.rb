class MeController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @addresses = @user.addresses
    @preferences = @user.preferences
    @recent_orders = @user.orders.order(created_at: :desc).limit(5)
    @recent_invoices = @user.orders.includes(:invoice).map(&:invoice).compact.sort_by(&:issued_at).reverse.first(5)
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(user_params)
      redirect_to me_path, notice: "Profil mis à jour"
    else
      flash.now[:alert] = @user.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def orders
    @user = current_user
    @orders = @user.orders.includes(:order_items, :invoice).order(created_at: :desc)
  end

  def order
    @order = current_user.orders.includes(:order_items, :payments, :invoice).find(params[:id])
  end

  def addresses
    @user = current_user
    @addresses = @user.addresses
  end

  def add_address
    @address = current_user.addresses.build
  end

  def create_address
    @address = current_user.addresses.build(address_params)

    if @address.save
      redirect_to me_addresses_path, notice: "Adresse ajoutée"
    else
      flash.now[:alert] = @address.errors.full_messages.join(", ")
      render :add_address, status: :unprocessable_entity
    end
  end

  def edit_address
    @address = current_user.addresses.find(params[:id])
  end

  def update_address
    @address = current_user.addresses.find(params[:id])

    if @address.update(address_params)
      redirect_to me_addresses_path, notice: "Adresse mise à jour"
    else
      flash.now[:alert] = @address.errors.full_messages.join(", ")
      render :edit_address, status: :unprocessable_entity
    end
  end

  def delete_address
    @address = current_user.addresses.find(params[:id])
    @address.destroy

    redirect_to me_addresses_path, notice: "Adresse supprimée"
  end

  def preferences
    @user = current_user
    @preferences = @user.preferences
  end

  def update_preferences
    @user = current_user
    @preferences = @user.preferences

    if @preferences.update(preferences_params)
      redirect_to me_preferences_path, notice: "Préférences mises à jour"
    else
      flash.now[:alert] = @preferences.errors.full_messages.join(", ")
      render :preferences, status: :unprocessable_entity
    end
  end

  def invoices
    @invoices = current_user.orders.includes(:invoice).map(&:invoice).compact.sort_by(&:issued_at).reverse
  end

  def invoice
    @invoice = find_user_invoice(params[:id])
  end

  def download_invoice
    invoice = find_user_invoice(params[:id])

    if invoice.pdf_ready?
      redirect_to invoice.pdf_url, allow_other_host: true
    else
      redirect_to me_invoice_path(invoice), alert: "La facture est en cours de génération. Réessayez dans quelques instants."
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :phone)
  end

  def address_params
    params.require(:address).permit(:address_type, :full_name, :street, :city, :postal_code, :country, :phone, :notes, :is_default)
  end

  def preferences_params
    params.require(:user_preference).permit(:notifications_email_order, :notifications_email_quote, :notifications_email_promotional)
  end

  def find_user_invoice(id)
    Invoice.joins(:order).where(orders: { user_id: current_user.id }).find(id)
  end
end
