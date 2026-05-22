module Admin
  class ReviewsController < BaseController
    def index
      @filters = {
        status: params[:status].presence,
        min_rating: params[:min_rating].presence,
        q: params[:q].to_s.strip.presence,
        date_from: params[:date_from].presence,
        date_to: params[:date_to].presence
      }

      scope = Review.includes(:user, :order)
      scope = scope.where(status: @filters[:status]) if @filters[:status]
      scope = scope.where("rating >= ?", @filters[:min_rating].to_i) if @filters[:min_rating]
      if @filters[:q]
        query = "%#{@filters[:q].downcase}%"
        scope = scope.where("LOWER(comment) LIKE ?", query)
      end
      scope = apply_created_at_range(scope, @filters[:date_from], @filters[:date_to])

      scope = apply_sort(
        scope,
        allowed_columns: %w[created_at rating status report_count],
        default_column: "created_at"
      )

      @reviews = paginate_scope(scope)
    end

    def bulk_status
      ids = Array(params[:review_ids]).map(&:to_i).uniq
      next_status = params.dig(:bulk, :status).to_s

      if ids.empty? || next_status.blank?
        return redirect_to admin_reviews_path, alert: "Selection et statut requis pour l'action en masse."
      end

      unless Review::STATUSES.include?(next_status)
        return redirect_to admin_reviews_path, alert: "Statut invalide."
      end

      updated = 0
      Review.where(id: ids).find_each do |review|
        review.update!(status: next_status)
        AuditLog.create!(
          user_id: current_user.id,
          action: "review_status_changed",
          resource_type: "Review",
          resource_id: review.id,
          request_id: request.request_id,
          metadata: { status: next_status, actor: "admin_web_bulk" }
        )
        updated += 1
      end

      redirect_to admin_reviews_path, notice: "#{updated} avis mis a jour."
    end

    def show
      @review = Review.includes(:user, :order).find(params[:id])
    end

    def status
      review = Review.find(params[:id])
      next_status = status_params.fetch(:status)

      unless Review::STATUSES.include?(next_status)
        return redirect_to admin_review_path(review), alert: "Statut invalide."
      end

      review.update!(status: next_status)
      AuditLog.create!(
        user_id: current_user.id,
        action: "review_status_changed",
        resource_type: "Review",
        resource_id: review.id,
        request_id: request.request_id,
        metadata: { status: next_status, actor: "admin_web" }
      )

      redirect_to admin_review_path(review), notice: "Statut de l'avis mis a jour."
    end

    private

    def apply_created_at_range(scope, date_from, date_to)
      if date_from.present?
        parsed_from = Date.parse(date_from) rescue nil
        scope = scope.where("reviews.created_at >= ?", parsed_from.beginning_of_day) if parsed_from
      end

      if date_to.present?
        parsed_to = Date.parse(date_to) rescue nil
        scope = scope.where("reviews.created_at <= ?", parsed_to.end_of_day) if parsed_to
      end

      scope
    end

    def status_params
      params.require(:review).permit(:status)
    end
  end
end
