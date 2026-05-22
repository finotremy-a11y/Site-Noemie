require "test_helper"

module Api
  module V1
    class CartControllerTest < ActionDispatch::IntegrationTest
      setup do
        @category = Category.create!(name: "Burgers", slug: "burgers", position: 1)
        @product = Product.create!(
          category: @category,
          name: "Burger Smash",
          description: "Simple et bon",
          price_cents: 1200,
          currency: "EUR",
          active: true,
          stock_quantity: 10,
          badges: []
        )
      end

      test "show creates cart from token" do
        get "/api/v1/cart", headers: { "X-Cart-Token" => "cart_test_1" }

        assert_response :success
        body = response.parsed_body
        assert_equal "cart_test_1", body.dig("data", "session_token")
      end

      test "create cart item" do
        post "/api/v1/cart/items",
             params: {
               item: {
                 product_id: @product.id,
                 quantity: 2,
                 options: { cheese: true }
               }
             },
             headers: { "X-Cart-Token" => "cart_test_2" }

        assert_response :created
        body = response.parsed_body
        assert_equal 2400, body.dig("data", "line_total_cents")
      end
    end
  end
end
