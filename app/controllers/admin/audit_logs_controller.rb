module Admin
  class AuditLogsController < BaseController
    def index
      @filters = {
        action: params[:action_name_filter].presence,
        resource_type: params[:resource_type].presence,
        q: params[:q].to_s.strip.presence,
        date_from: params[:date_from].presence,
        date_to: params[:date_to].presence
      }

      scope = AuditLog.includes(:user).recent
      scope = scope.where(action: @filters[:action]) if @filters[:action]
      scope = scope.where(resource_type: @filters[:resource_type]) if @filters[:resource_type]
      if @filters[:q]
        query = "%#{@filters[:q].downcase}%"
        scope = scope.where("LOWER(COALESCE(request_id, '')) LIKE :query OR CAST(resource_id AS TEXT) LIKE :id_query",
                            query: query,
                            id_query: "%#{@filters[:q]}%")
      end
      scope = apply_created_at_range(scope, @filters[:date_from], @filters[:date_to])

      scope = apply_sort(
        scope,
        allowed_columns: %w[created_at action resource_type resource_id],
        default_column: "created_at"
      )

      @audit_logs = paginate_scope(scope, default_per_page: 40)
    end

    def show
      @audit_log = AuditLog.includes(:user).find(params[:id])
    end

    private

    def apply_created_at_range(scope, date_from, date_to)
      if date_from.present?
        parsed_from = Date.parse(date_from) rescue nil
        scope = scope.where("audit_logs.created_at >= ?", parsed_from.beginning_of_day) if parsed_from
      end

      if date_to.present?
        parsed_to = Date.parse(date_to) rescue nil
        scope = scope.where("audit_logs.created_at <= ?", parsed_to.end_of_day) if parsed_to
      end

      scope
    end
  end
end
