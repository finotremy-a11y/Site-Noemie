require "test_helper"

module Api
  module V1
    module Admin
      class ReviewsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @previous_token = ENV["ADMIN_API_TOKEN"]
          ENV["ADMIN_API_TOKEN"] = "test_admin_token"

          @admin = User.create!(email: "reviews-admin@example.com", role: "admin", active: true)
          @admin.generate_api_token
          @admin.save!

          @review = Review.create!(rating: 3, comment: "Moyen", status: "pending", report_count: 0)
        end

        teardown do
          ENV["ADMIN_API_TOKEN"] = @previous_token
        end

        test "index with admin token" do
          get "/api/v1/admin/reviews", headers: admin_headers

          assert_response :ok
          assert_equal 1, response.parsed_body.fetch("data").size
        end

        test "status update" do
          patch "/api/v1/admin/reviews/#{@review.id}/status",
                params: { review: { status: "approved" } },
                headers: admin_headers

          assert_response :ok
          @review.reload
          assert_equal "approved", @review.status
        end

        private

        def admin_headers
          {
            "X-Admin-Token" => "test_admin_token",
            "X-Customer-Token" => @admin.api_token
          }
        end
      end
    end
  end
end
