module Api
  module V1
    class ReviewsController < BaseController
      def index
        reviews = Review.approved.order(created_at: :desc).limit(100)

        render json: {
          data: reviews.map { |review| serialize_review(review) }
        }, status: :ok
      end

      def create
        review = Review.new(review_params.merge(status: "pending"))

        if review.save
          render json: {
            data: serialize_review(review)
          }, status: :created
        else
          render_error(
            code: "validation_error",
            message: "Parametres invalides.",
            details: { errors: review.errors.full_messages },
            status: :unprocessable_entity
          )
        end
      end

      def report
        review = Review.find_by(id: params[:id])
        return render_not_found unless review

        review.increment!(:report_count)
        review.update!(status: "hidden") if review.report_count >= 3 && review.status == "approved"

        render json: {
          data: {
            id: review.id,
            report_count: review.report_count,
            status: review.status
          }
        }, status: :ok
      end

      private

      def review_params
        params.require(:review).permit(:user_id, :order_id, :rating, :comment)
      end

      def serialize_review(review)
        {
          id: review.id,
          order_id: review.order_id,
          rating: review.rating,
          comment: review.comment,
          status: review.status,
          created_at: review.created_at
        }
      end

      def render_not_found
        render_error(
          code: "not_found",
          message: "Avis introuvable.",
          status: :not_found
        )
      end
    end
  end
end
