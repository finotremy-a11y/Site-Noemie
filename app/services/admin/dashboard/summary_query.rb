module Admin
  module Dashboard
    class SummaryQuery
      LOOKBACK_DAYS = 30

      def initialize(period_days: LOOKBACK_DAYS, date_from: nil, date_to: nil)
        @period_days = [ 7, 30, 90 ].include?(period_days.to_i) ? period_days.to_i : LOOKBACK_DAYS
        @date_from = date_from
        @date_to = date_to
      end

      def call
        range = analysis_range

        {
          generated_at: Time.current,
          range: {
            from: range.begin,
            to: range.end,
            label: range_label(range)
          },
          kpis: {
            orders_today: orders_today_count,
            revenue_today_cents: revenue_today_cents,
            average_basket_today_cents: average_basket_today_cents,
            conversion_rate_30d: conversion_rate_over(range),
            conversion_rate_period: conversion_rate_over(range)
          },
          operations: {
            pending_orders: Order.where(status: %w[pending_payment pending_validation]).count,
            preparing_orders: Order.where(status: "preparing").count,
            pending_quotes: Quote.where(status: "new").count,
            pending_reviews: Review.where(status: "pending").count
          },
          by_status: Order.group(:status).count
        }
      end

      private

      def orders_today_scope
        Order.where(created_at: Time.zone.today.all_day)
      end

      def orders_today_count
        orders_today_scope.count
      end

      def revenue_today_cents
        orders_today_scope.where(payment_status: "paid").sum(:total_cents)
      end

      def average_basket_today_cents
        paid_scope = orders_today_scope.where(payment_status: "paid")
        return 0 if paid_scope.none?

        (paid_scope.sum(:total_cents).to_f / paid_scope.count).round
      end

      def conversion_rate_30d
        conversion_rate_over(analysis_range)
      end

      def conversion_rate_over(range)
        scope = Order.where(created_at: range)
        total = scope.count
        return 0.0 if total.zero?

        converted = scope.where(status: %w[confirmed preparing ready completed]).count
        ((converted.to_f / total) * 100).round(2)
      end

      def analysis_range
        if @date_from.present? || @date_to.present?
          from = (@date_from || @period_days.days.ago.to_date).beginning_of_day
          to = (@date_to || Time.zone.today).end_of_day
          return from..to
        end

        @period_days.days.ago.beginning_of_day..Time.current
      end

      def range_label(range)
        "#{I18n.l(range.begin.to_date, format: :short)} - #{I18n.l(range.end.to_date, format: :short)}"
      end
    end
  end
end
