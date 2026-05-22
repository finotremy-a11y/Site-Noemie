module Api
  module V1
    module Admin
      class ReviewsController < BaseController
        def index
          scope = Review.order(created_at: :desc)
          scope = scope.where(status: params[:status]) if params[:status].present?

          render json: {
            data: scope.limit(200).map { |review| serialize_review(review) }
          }, status: :ok
        end

        def status
          review = Review.find_by(id: params[:id])
          return render_not_found unless review

          next_status = status_params.fetch(:status)
          unless Review::STATUSES.include?(next_status)
            return render_error(
              code: "validation_error",
              message: "Statut invalide.",
              details: { allowed: Review::STATUSES },
              status: :unprocessable_entity
            )
          end

          review.update!(status: next_status)

          AuditLog.create!(
            action: "review_status_changed",
            resource_type: "Review",
            resource_id: review.id,
            request_id: request.request_id,
            metadata: {
              status: next_status,
              actor: "admin_api"
            }
          )

          render json: { data: serialize_review(review) }, status: :ok
        end

        private

        def status_params
          params.require(:review).permit(:status)
        end

        def render_not_found
          render_error(
            code: "not_found",
            message: "Avis introuvable.",
            status: :not_found
          )
        end

        def serialize_review(review)
          {
            id: review.id,
            order_id: review.order_id,
            rating: review.rating,
            comment: review.comment,
            status: review.status,
            report_count: review.report_count,
            created_at: review.created_at,
            updated_at: review.updated_at
          }
        end
      end
    end
  end
end
