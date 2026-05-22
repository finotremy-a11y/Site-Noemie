module Notifications
  class SendInvoiceReadyEmailJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: 5.minutes, attempts: 3

    def perform(invoice_id)
      invoice = Invoice.find(invoice_id)
      order = invoice.order
      customer = order.user

      if customer&.preference&.notifications_email_order && invoice.pdf_ready?
        NotificationMailer.invoice_ready(invoice_id).deliver_later
      end

      log_notification(invoice)
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn("Invoice #{invoice_id} not found for email notification")
    end

    private

    def log_notification(invoice)
      Rails.logger.info("Sent invoice_ready notification for #{invoice.invoice_number}")
    end
  end
end
