module Api
  module V1
    module Admin
      class AuditLogsController < BaseController
        before_action :authenticate_admin!

        def index
          resource_type = params[:resource_type]
          resource_id = params[:resource_id]
          page = (params[:page] || 1).to_i
          per_page = 50

          logs = AuditLog.recent

          if resource_type.present? && resource_id.present?
            logs = logs.for_resource(resource_type, resource_id)
          end

          if params[:user_id].present?
            logs = logs.for_user(params[:user_id])
          end

          total_count = logs.count
          logs = logs.offset((page - 1) * per_page).limit(per_page)

          render json: {
            data: logs.map { |log| serialize_audit_log(log) },
            pagination: {
              page: page,
              per_page: per_page,
              total_count: total_count,
              total_pages: (total_count.to_f / per_page).ceil
            }
          }
        end

        def show
          log = AuditLog.find(params[:id])
          render json: { data: serialize_audit_log(log) }
        rescue ActiveRecord::RecordNotFound
          render_error(code: "not_found", message: "Audit log non trouvé", status: :not_found)
        end

        private

        def serialize_audit_log(log)
          {
            id: log.id,
            action: log.display_action,
            resource_type: log.resource_type,
            resource_id: log.resource_id,
            user_email: log.user&.email,
            changes: log.metadata,
            created_at: log.created_at
          }
        end

        def authenticate_admin!
          return if current_user&.admin?

          render_error(
            code: "forbidden",
            message: "Accès admin requis.",
            status: :forbidden
          )
        end
      end
    end
  end
end
