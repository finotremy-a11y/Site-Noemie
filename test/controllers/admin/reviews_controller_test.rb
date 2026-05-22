require "test_helper"

module Admin
  class ReviewsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = User.create!(
        email: "nl.cuisinent@gmail.com",
        password: "password123",
        role: "admin"
      )

      @review = Review.create!(
        rating: 4,
        comment: "Super prestation",
        status: "pending"
      )

      login_as_admin
    end

    test "index accepts filters and sort params" do
      get admin_reviews_path, params: {
        status: "pending",
        min_rating: 3,
        q: "prestation",
        date_from: 1.day.ago.to_date.to_s,
        date_to: Date.current.to_s,
        sort: "rating",
        direction: "asc"
      }

      assert_response :success
      assert_includes response.body, "Modération des avis"
    end

    test "status update changes review state" do
      patch status_admin_review_path(@review), params: {
        review: { status: "approved" }
      }

      assert_redirected_to admin_review_path(@review)
      @review.reload
      assert_equal "approved", @review.status
      assert_equal 1, AuditLog.where(resource_type: "Review", resource_id: @review.id, action: "review_status_changed").count
    end

    test "bulk status updates selected reviews" do
      other_review = Review.create!(
        rating: 2,
        comment: "Moyen",
        status: "pending"
      )

      patch bulk_status_admin_reviews_path, params: {
        review_ids: [ @review.id, other_review.id ],
        bulk: { status: "approved" }
      }

      assert_redirected_to admin_reviews_path
      assert_equal "approved", @review.reload.status
      assert_equal "approved", other_review.reload.status
    end

    private

    def login_as_admin
      post "/auth/login", params: {
        email: @admin.email,
        password: "password123"
      }
      follow_redirect!
    end
  end
end
