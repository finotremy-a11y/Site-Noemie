require "test_helper"

module Admin
  class ProductsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = User.create!(
        email: "nl.cuisinent@gmail.com",
        password: "password123",
        role: "admin"
      )

      @category = Category.create!(name: "Lunch Box", slug: "lunch-box", position: 1, active: true)

      @product = Product.create!(
        name: "Wrap Poulet",
        description: "Wrap maison",
        price_cents: 1290,
        currency: "EUR",
        active: true,
        stock_quantity: 12,
        category: @category
      )

      login_as_admin
    end

    test "create product from admin web" do
      assert_difference -> { Product.count }, 1 do
        post admin_products_path, params: {
          product: {
            name: "Salade Cesar",
            description: "Fraiche du jour",
            price_cents: 1490,
            currency: "EUR",
            active: true,
            stock_quantity: 10,
            image_url: "https://images.example.com/salade.jpg",
            category_id: @category.id,
            badges_text: "frais, bestseller"
          }
        }
      end

      created = Product.order(:created_at).last
      assert_redirected_to admin_product_path(created)
      assert_equal [ "frais", "bestseller" ], created.badges
      assert_equal "https://images.example.com/salade.jpg", created.image_url
    end

    test "index accepts sort parameters" do
      get admin_products_path, params: {
        sort: "price_cents",
        direction: "desc"
      }

      assert_response :success
      assert_includes response.body, "Catalogue produits"
    end

    test "update product tracks price change" do
      assert_difference -> { ProductPriceChange.count }, 1 do
        patch admin_product_path(@product), params: {
          product: {
            name: @product.name,
            description: @product.description,
            price_cents: 1390,
            currency: "EUR",
            active: true,
            stock_quantity: @product.stock_quantity,
            category_id: @category.id,
            badges_text: "edition-limitee"
          }
        }
      end

      assert_redirected_to admin_product_path(@product)
      @product.reload
      assert_equal 1390, @product.price_cents
      assert_equal [ "edition-limitee" ], @product.badges
    end

    test "bulk update can deactivate and activate products" do
      second_product = Product.create!(
        name: "Mini Burger",
        description: "Pain brioché",
        price_cents: 990,
        currency: "EUR",
        active: true,
        stock_quantity: 8,
        category: @category
      )

      patch bulk_update_admin_products_path, params: {
        product_ids: [ @product.id, second_product.id ],
        bulk: { action: "deactivate" }
      }

      assert_redirected_to admin_products_path
      assert_not @product.reload.active?
      assert_not second_product.reload.active?

      patch bulk_update_admin_products_path, params: {
        product_ids: [ @product.id ],
        bulk: { action: "activate" }
      }

      assert_redirected_to admin_products_path
      assert @product.reload.active?
    end

    test "destroy product from admin web" do
      assert_difference -> { Product.count }, -1 do
        delete admin_product_path(@product)
      end

      assert_redirected_to admin_products_path
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
