module Documents
  class UploadInvoiceToCloudinary
    attr_reader :invoice, :pdf_content, :error_message

    def initialize(invoice)
      @invoice = invoice
    end

    def call
      return false unless invoice.pdf_url.blank?

      begin
        pdf_content = Documents::InvoiceGenerator.new(invoice).generate_pdf

        upload_result = Cloudinary::Uploader.upload_large(
          StringIO.new(pdf_content),
          resource_type: "raw",
          folder: "invoices/#{Date.today.year}",
          public_id: "#{invoice.invoice_number}-#{invoice.id}",
          type: "authenticated",
          format: "pdf"
        )

        invoice.update(pdf_url: upload_result["secure_url"])
        true
      rescue StandardError => e
        @error_message = e.message
        Rails.logger.error("Failed to upload invoice #{invoice.id}: #{error_message}")
        false
      end
    end
  end
end
