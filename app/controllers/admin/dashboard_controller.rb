module Admin
  class DashboardController < BaseController
    def show
      @period = period_params

      @summary = Admin::Dashboard::SummaryQuery.new(
        period_days: @period[:period_days],
        date_from: @period[:date_from],
        date_to: @period[:date_to]
      ).call

      range = @summary[:range]
      scoped_orders = Order.where(created_at: range[:from]..range[:to])
      @recent_orders = scoped_orders.includes(:order_items).order(created_at: :desc).limit(8)
      @pending_quotes = Quote.where(status: "new").order(created_at: :desc).limit(5)
      @pending_reviews = Review.where(status: "pending").order(created_at: :desc).limit(5)
      @low_stock_products = Product.includes(:category).where(active: true).order(stock_quantity: :asc).limit(6)

      @daily_revenue_7d = (6.downto(0)).map do |days_ago|
        date = days_ago.days.ago.to_date
        revenue_cents = Order.where(created_at: date.all_day, payment_status: "paid").sum(:total_cents)
        day_labels = %w[D L M M J V S]
        { date: date, label: day_labels[date.wday], revenue_cents: revenue_cents, today: days_ago == 0 }
      end

      @revenue_today_cents = @summary.dig(:kpis, :revenue_today_cents).to_i
      @orders_today = @summary.dig(:kpis, :orders_today).to_i
      @avg_basket_cents = @summary.dig(:kpis, :average_basket_today_cents).to_i
      @recent_invoices = Invoice.includes(:order).order(created_at: :desc).limit(5)
    end

    private

    def period_params
      period_days = params[:period_days].to_i
      period_days = 30 unless [ 7, 30, 90 ].include?(period_days)

      {
        period_days: period_days,
        date_from: safe_date(params[:date_from]),
        date_to: safe_date(params[:date_to])
      }
    end

    def safe_date(value)
      return if value.blank?

      Date.parse(value)
    rescue ArgumentError
      nil
    end
  end
end
