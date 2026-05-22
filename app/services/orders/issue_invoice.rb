module Orders
  class IssueInvoice
    def initialize(order:)
      @order = order
    end

    def call
      return order.invoice if order.respond_to?(:invoice) && order.invoice.present?

      Invoice.create!(
        order: order,
        invoice_number: next_invoice_number,
        total_cents: order.total_cents,
        status: "issued",
        issued_at: Time.current
      )
    end

    private

    attr_reader :order

    def next_invoice_number
      date_prefix = Time.current.strftime("%Y%m")
      sequence = Invoice.where("invoice_number LIKE ?", "INV-#{date_prefix}-%").count + 1
      "INV-#{date_prefix}-#{sequence.to_s.rjust(5, "0")}"
    end
  end
end
