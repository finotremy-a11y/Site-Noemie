module Admin
  class QuotesController < BaseController
    def index
      @filters = {
        status: params[:status].presence,
        q: params[:q].to_s.strip.presence,
        date_from: params[:date_from].presence,
        date_to: params[:date_to].presence
      }

      scope = Quote.all
      scope = scope.where(status: @filters[:status]) if @filters[:status]
      if @filters[:q]
        query = "%#{@filters[:q].downcase}%"
        scope = scope.where("LOWER(email) LIKE :query OR LOWER(COALESCE(event_type, '')) LIKE :query", query: query)
      end
      scope = apply_created_at_range(scope, @filters[:date_from], @filters[:date_to])

      scope = apply_sort(
        scope,
        allowed_columns: %w[created_at event_date guest_count status email],
        default_column: "created_at"
      )

      @quotes = paginate_scope(scope)
    end

    def bulk_status
      ids = Array(params[:quote_ids]).map(&:to_i).uniq
      next_status = params.dig(:bulk, :status).to_s

      if ids.empty? || next_status.blank?
        return redirect_to admin_quotes_path, alert: "Selection et statut requis pour l'action en masse."
      end

      unless Quote::STATUSES.include?(next_status)
        return redirect_to admin_quotes_path, alert: "Statut invalide."
      end

      updated = 0
      Quote.where(id: ids).find_each do |quote|
        quote.update!(status: next_status)

        Notifications::CustomerNotificationJob.perform_later(
          to: quote.email,
          subject: "[N&L Cuisinent] Mise a jour de votre devis",
          lines: [
            "Votre demande de devis ##{quote.id} a ete mise a jour.",
            "Nouveau statut: #{next_status}"
          ]
        )

        AuditLog.create!(
          user_id: current_user.id,
          action: "quote_status_changed",
          resource_type: "Quote",
          resource_id: quote.id,
          request_id: request.request_id,
          metadata: { status: next_status, actor: "admin_web_bulk" }
        )
        updated += 1
      end

      redirect_to admin_quotes_path, notice: "#{updated} devis mis a jour."
    end

    def show
      @quote = Quote.find(params[:id])
    end

    def status
      quote = Quote.find(params[:id])
      next_status = status_params.fetch(:status)

      unless Quote::STATUSES.include?(next_status)
        return redirect_to admin_quote_path(quote), alert: "Statut invalide."
      end

      quote.update!(status: next_status)

      Notifications::CustomerNotificationJob.perform_later(
        to: quote.email,
        subject: "[N&L Cuisinent] Mise a jour de votre devis",
        lines: [
          "Votre demande de devis ##{quote.id} a ete mise a jour.",
          "Nouveau statut: #{next_status}"
        ]
      )

      AuditLog.create!(
        user_id: current_user.id,
        action: "quote_status_changed",
        resource_type: "Quote",
        resource_id: quote.id,
        request_id: request.request_id,
        metadata: { status: next_status, actor: "admin_web" }
      )

      redirect_to admin_quote_path(quote), notice: "Statut du devis mis a jour."
    end

    private

    def apply_created_at_range(scope, date_from, date_to)
      if date_from.present?
        parsed_from = Date.parse(date_from) rescue nil
        scope = scope.where("quotes.created_at >= ?", parsed_from.beginning_of_day) if parsed_from
      end

      if date_to.present?
        parsed_to = Date.parse(date_to) rescue nil
        scope = scope.where("quotes.created_at <= ?", parsed_to.end_of_day) if parsed_to
      end

      scope
    end

    def status_params
      params.require(:quote).permit(:status)
    end
  end
end
