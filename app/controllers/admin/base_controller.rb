module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_sidebar_counts

    layout "admin"

    private

    def apply_sort(scope, allowed_columns:, default_column:, default_direction: "desc")
      requested_column = params[:sort].to_s
      requested_direction = params[:direction].to_s

      column = allowed_columns.include?(requested_column) ? requested_column : default_column
      direction = %w[asc desc].include?(requested_direction) ? requested_direction : default_direction

      @sorting = {
        column: column,
        direction: direction
      }

      scope.order(column => direction)
    end

    def next_sort_direction(column)
      return "asc" unless @sorting&.dig(:column) == column

      @sorting[:direction] == "asc" ? "desc" : "asc"
    end

    helper_method :sort_params_for, :sort_indicator

    def sort_params_for(column)
      request.query_parameters.merge(sort: column, direction: next_sort_direction(column), page: 1)
    end

    def sort_indicator(column)
      return "" unless @sorting&.dig(:column) == column

      @sorting[:direction] == "asc" ? " (asc)" : " (desc)"
    end

    def paginate_scope(scope, default_per_page: 25, max_per_page: 100)
      page = params.fetch(:page, 1).to_i
      page = 1 if page < 1

      per_page = params.fetch(:per_page, default_per_page).to_i
      per_page = default_per_page if per_page < 1
      per_page = max_per_page if per_page > max_per_page

      total_count = scope.count
      total_pages = (total_count.to_f / per_page).ceil
      total_pages = 1 if total_pages.zero?

      records = scope.offset((page - 1) * per_page).limit(per_page)
      @pagination = {
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_pages
      }

      records
    end

    def require_admin!
      return if current_user&.admin? && current_user.active?
      redirect_to root_path, alert: "Accès administrateur requis"
    end

    def set_sidebar_counts
      @sidebar_pending_orders = Order.where(status: %w[pending_payment pending_validation new]).count
      @sidebar_pending_quotes = Quote.where(status: "new").count
      @sidebar_pending_reviews = Review.where(status: "pending").count
    end
  end
end
