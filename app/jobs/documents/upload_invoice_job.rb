module Documents
  class UploadInvoiceJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: 5.minutes, attempts: 3

    def perform(invoice_id)
      invoice = Invoice.find(invoice_id)
      uploaded = Documents::UploadInvoiceToCloudinary.new(invoice).call
      Notifications::SendInvoiceReadyEmailJob.perform_later(invoice.id) if uploaded && invoice.reload.pdf_ready?
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn("Invoice #{invoice_id} not found for PDF upload")
    end
  end
end
