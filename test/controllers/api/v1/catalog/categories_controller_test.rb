require "test_helper"

module Api
  module V1
    module Catalog
      class CategoriesControllerTest < ActionDispatch::IntegrationTest
        setup do
          Category.create!(name: "Desserts", slug: "desserts", position: 2)
          Category.create!(name: "Burgers", slug: "burgers", position: 1)
          Category.create!(name: "Archives", slug: "archives", position: 99, active: false)
        end

        test "index returns active ordered categories" do
          get "/api/v1/catalog/categories"

          assert_response :success
          body = response.parsed_body
          assert_equal 2, body["data"].size
          assert_equal "Burgers", body["data"].first["name"]
          assert_equal "Desserts", body["data"].second["name"]
        end
      end
    end
  end
end
