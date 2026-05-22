class NotificationMailer < ApplicationMailer
  def order_confirmation(order_id)
    @order = Order.find(order_id)
    @customer = @order.user

    mail(
      to: @customer.email,
      subject: "Confirmation de votre commande #{@order.order_number}"
    )
  end

  def order_status_update(order_id, new_status)
    @order = Order.find(order_id)
    @customer = @order.user
    @new_status = I18n.t("enums.order.status.#{new_status}")

    mail(
      to: @customer.email,
      subject: "Mise à jour de votre commande #{@order.order_number}"
    )
  end

  def payment_confirmation(order_id)
    @order = Order.find(order_id)
    @customer = @order.user

    mail(
      to: @customer.email,
      subject: "Paiement reçu pour la commande #{@order.order_number}"
    )
  end

  def invoice_ready(invoice_id)
    @invoice = Invoice.find(invoice_id)
    @order = @invoice.order
    @customer = @order.user

    mail(
      to: @customer.email,
      subject: "Votre facture #{@invoice.invoice_number} est disponible"
    )
  end

  def quote_status_update(quote_id, new_status)
    @quote = Quote.find(quote_id)
    @new_status = I18n.t("enums.quote.status.#{new_status}")

    mail(
      to: @quote.email,
      subject: "Mise à jour de votre devis #{@quote.id}"
    )
  end
end
