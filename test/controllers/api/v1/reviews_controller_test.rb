require "test_helper"

module Api
  module V1
    class ReviewsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @review = Review.create!(rating: 5, comment: "Excellent", status: "approved", report_count: 0)
      end

      test "index returns approved reviews" do
        get "/api/v1/reviews"

        assert_response :ok
        assert_equal 1, response.parsed_body.fetch("data").size
      end

      test "create review creates pending review" do
        post "/api/v1/reviews", params: { review: { rating: 4, comment: "Tres bon" } }

        assert_response :created
        assert_equal "pending", response.parsed_body.dig("data", "status")
      end

      test "report review increments report count" do
        post "/api/v1/reviews/#{@review.id}/report"

        assert_response :ok
        @review.reload
        assert_equal 1, @review.report_count
      end
    end
  end
end
