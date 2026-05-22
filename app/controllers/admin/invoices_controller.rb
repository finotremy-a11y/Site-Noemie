module Admin
  class InvoicesController < BaseController
    def index
      @filters = {
        status: params[:status].presence,
        q: params[:q].to_s.strip.presence,
        date_from: params[:date_from].presence,
        date_to: params[:date_to].presence
      }

      scope = Invoice.includes(:order)
      scope = scope.where(status: @filters[:status]) if @filters[:status]
      if @filters[:q]
        query = "%#{@filters[:q].downcase}%"
        scope = scope.joins("LEFT JOIN orders ON orders.id = invoices.order_id")
                     .where("LOWER(invoices.invoice_number) LIKE :query OR LOWER(orders.order_number) LIKE :query", query: query)
      end
      scope = apply_issued_at_range(scope, @filters[:date_from], @filters[:date_to])

      scope = apply_sort(
        scope,
        allowed_columns: %w[created_at issued_at total_cents status invoice_number],
        default_column: "issued_at"
      )

      @invoices = paginate_scope(scope)
    end

    def show
      @invoice = Invoice.includes(:order).find(params[:id])
    end

    private

    def apply_issued_at_range(scope, date_from, date_to)
      if date_from.present?
        parsed_from = Date.parse(date_from) rescue nil
        scope = scope.where("COALESCE(invoices.issued_at, invoices.created_at) >= ?", parsed_from.beginning_of_day) if parsed_from
      end

      if date_to.present?
        parsed_to = Date.parse(date_to) rescue nil
        scope = scope.where("COALESCE(invoices.issued_at, invoices.created_at) <= ?", parsed_to.end_of_day) if parsed_to
      end

      scope
    end
  end
end
