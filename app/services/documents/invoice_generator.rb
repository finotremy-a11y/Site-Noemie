module Documents
  class InvoiceGenerator
    require "prawn"
    require "prawn/table"

    attr_reader :invoice

    def initialize(invoice)
      @invoice = invoice
    end

    def generate_pdf
      pdf = Prawn::Document.new(compress: false)
      render_header(pdf)
      render_invoice_details(pdf)
      render_items_table(pdf)
      render_totals(pdf)
      render_footer(pdf)

      pdf.render
    end

    private

    def render_header(pdf)
      pdf.font_size 20
      pdf.text "N&L Cuisinent", style: :bold, color: "B23A30"
      pdf.font_size 10
      pdf.text "Facture", style: :bold
      pdf.move_down 10

      pdf.font_size 9
      pdf.text "Numéro: #{invoice.invoice_number}"
      pdf.text "Date d'émission: #{issued_on}"
    end

    def render_invoice_details(pdf)
      pdf.move_down 15

      order = invoice.order
      customer = order.user

      pdf.font_size 11
      pdf.text "Facturé à:", style: :bold

      pdf.font_size 9
      pdf.text(customer&.email || order.customer_email)
      pdf.text order.customer_phone if order.customer_phone.present?
      pdf.text order.delivery_address if order.delivery_address.present?
    end

    def render_items_table(pdf)
      pdf.move_down 20

      data = [ [ "Produit", "Quantité", "Prix unitaire", "Total" ] ]

      invoice.order.order_items.each do |item|
        data << [
          item.name,
          item.quantity.to_s,
          format_eur(item.unit_price_cents),
          format_eur(item.line_total_cents)
        ]
      end

      pdf.table(data, width: pdf.bounds.width, cell_style: { size: 9, border_color: "CCCCCC" })
    end

    def render_totals(pdf)
      order = invoice.order

      pdf.move_down 15
      pdf.font_size 10
      pdf.text "Sous-total: #{format_eur(order.subtotal_cents)}"
      pdf.text "Livraison: #{format_eur(order.delivery_fee_cents)}"

      pdf.font_size 12
      pdf.text "Total: #{format_eur(invoice.total_cents)}", style: :bold, color: "B23A30"
    end

    def render_footer(pdf)
      pdf.move_down 30

      pdf.font_size 8
      pdf.text "Merci pour votre commande ! | N&L Cuisinent | Conditions générales sur www.nlcuisinent.com"
    end

    def issued_on
      (invoice.issued_at || invoice.created_at || Time.current).strftime("%d/%m/%Y")
    end

    def format_eur(amount_cents)
      format("%.2f €", amount_cents.to_i / 100.0)
    end
  end
end
