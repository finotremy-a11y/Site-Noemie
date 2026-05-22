require "test_helper"

module Api
  module V1
    module Admin
      class ProductsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @previous_token = ENV["ADMIN_API_TOKEN"]
          ENV["ADMIN_API_TOKEN"] = "test_admin_token"

          @admin = User.create!(email: "products-admin@example.com", role: "admin", active: true)
          @admin.generate_api_token
          @admin.save!

          @category = Category.create!(name: "Burgers", slug: "burgers", position: 1)
          @product = Product.create!(
            category: @category,
            name: "Burger Smash",
            description: "Double steak",
            price_cents: 1390,
            currency: "EUR",
            active: true,
            stock_quantity: 5,
            badges: [ "spicy" ]
          )
        end

        teardown do
          ENV["ADMIN_API_TOKEN"] = @previous_token
        end

        test "index forbids without admin token" do
          get "/api/v1/admin/products"

          assert_response :forbidden
        end

        test "create product with admin token" do
          post "/api/v1/admin/products",
               params: {
                 product: {
                   category_id: @category.id,
                   name: "Burger Truffe",
                   description: "Sauce truffe",
                   price_cents: 1690,
                   currency: "EUR",
                   active: true,
                   stock_quantity: 3,
                   badges: [ "new" ]
                 }
               },
               headers: admin_headers

          assert_response :created
          body = response.parsed_body
          assert_equal "Burger Truffe", body.dig("data", "name")
        end

        test "update product records price history" do
          patch "/api/v1/admin/products/#{@product.id}",
                params: {
                  product: { price_cents: 1490 },
                  price_change_reason: "Hausse matiere premiere"
                },
                headers: admin_headers

          assert_response :success
          assert_equal 1, @product.product_price_changes.count
          change = @product.product_price_changes.last
          assert_equal 1390, change.old_price_cents
          assert_equal 1490, change.new_price_cents
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
