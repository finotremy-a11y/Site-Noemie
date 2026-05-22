module Admin
  class OrdersController < BaseController
    def index
      @filters = {
        status: params[:status].presence,
        payment_status: params[:payment_status].presence,
        service_mode: params[:service_mode].presence,
        q: params[:q].to_s.strip.presence,
        date_from: params[:date_from].presence,
        date_to: params[:date_to].presence
      }

      scope = Order.includes(:order_items, :user)
      scope = scope.where(status: @filters[:status]) if @filters[:status]
      scope = scope.where(payment_status: @filters[:payment_status]) if @filters[:payment_status]
      scope = scope.where(service_mode: @filters[:service_mode]) if @filters[:service_mode]
      if @filters[:q]
        query = "%#{@filters[:q].downcase}%"
        scope = scope.where("LOWER(order_number) LIKE :query OR LOWER(customer_email) LIKE :query", query: query)
      end
      scope = apply_created_at_range(scope, @filters[:date_from], @filters[:date_to])

      scope = apply_sort(
        scope,
        allowed_columns: %w[created_at order_number status payment_status total_cents service_mode],
        default_column: "created_at"
      )

      @orders = paginate_scope(scope)
    end

    def bulk_status
      ids = Array(params[:order_ids]).map(&:to_i).uniq
      target_status = params.dig(:bulk, :status).to_s

      if ids.empty? || target_status.blank?
        return redirect_to admin_orders_path, alert: "Selection et statut requis pour l'action en masse."
      end

      success_count = 0
      failed_count = 0

      Order.where(id: ids).find_each do |order|
        begin
          Orders::TransitionStatus.new(
            order: order,
            to_status: target_status,
            actor: current_user,
            request_id: request.request_id,
            reason: "Action en masse"
          ).call
          success_count += 1
        rescue Orders::TransitionStatus::ValidationError, Orders::TransitionStatus::ConflictError
          failed_count += 1
        end
      end

      message = "#{success_count} commande(s) mise(s) a jour"
      message += ", #{failed_count} en echec" if failed_count.positive?
      redirect_to admin_orders_path, notice: message
    end

    def show
      @order = Order.includes(:order_items, :payments, :invoice, :user).find(params[:id])
    end

    def status
      order = Order.find(params[:id])

      Orders::TransitionStatus.new(
        order: order,
        to_status: status_params.fetch(:status),
        actor: current_user,
        request_id: request.request_id,
        reason: status_params[:reason]
      ).call

      redirect_to admin_order_path(order), notice: "Statut de commande mis a jour."
    rescue Orders::TransitionStatus::ValidationError => error
      redirect_to admin_order_path(order), alert: "Transition invalide: #{error.details.to_json}"
    rescue Orders::TransitionStatus::ConflictError => error
      redirect_to admin_order_path(order), alert: "Transition refusee: #{error.details.to_json}"
    end

    private

    def apply_created_at_range(scope, date_from, date_to)
      if date_from.present?
        parsed_from = Date.parse(date_from) rescue nil
        scope = scope.where("orders.created_at >= ?", parsed_from.beginning_of_day) if parsed_from
      end

      if date_to.present?
        parsed_to = Date.parse(date_to) rescue nil
        scope = scope.where("orders.created_at <= ?", parsed_to.end_of_day) if parsed_to
      end

      scope
    end

    def status_params
      params.require(:order).permit(:status, :reason)
    end
  end
end
