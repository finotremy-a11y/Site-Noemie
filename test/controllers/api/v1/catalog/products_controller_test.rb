require "test_helper"

module Api
  module V1
    module Catalog
      class ProductsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @category = Category.create!(name: "Burgers", slug: "burgers", position: 1)
          @product = Product.create!(
            category: @category,
            name: "Burger Classic",
            description: "Steak, cheddar, sauce maison",
            price_cents: 1290,
            currency: "EUR",
            active: true,
            stock_quantity: 10,
            badges: [ "best-seller" ]
          )
          ProductOption.create!(
            product: @product,
            name: "Bacon",
            price_delta_cents: 150,
            active: true
          )
        end

        test "index returns paginated products" do
          get "/api/v1/catalog/products", params: { page: 1, limit: 10 }

          assert_response :success
          body = response.parsed_body
          assert_equal 1, body["meta"]["total"]
          assert_equal "Burger Classic", body["data"].first["name"]
        end

        test "index filters by search" do
          get "/api/v1/catalog/products", params: { q: "Classic" }

          assert_response :success
          body = response.parsed_body
          assert_equal 1, body["data"].size
        end

        test "show returns not found for unknown id" do
          get "/api/v1/catalog/products/999999"

          assert_response :not_found
          body = response.parsed_body
          assert_equal "not_found", body.dig("error", "code")
        end
      end
    end
  end
end
