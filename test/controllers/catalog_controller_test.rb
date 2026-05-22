require "test_helper"

class CatalogControllerTest < ActionDispatch::IntegrationTest
  setup do
    @category = Category.create!(name: "Burgers", slug: "burgers", position: 1, active: true)

    13.times do |index|
      Product.create!(
        category: @category,
        name: "Burger #{index}",
        description: "Burger signature #{index}",
        price_cents: 1200,
        currency: "EUR",
        active: true,
        stock_quantity: 10,
        badges: []
      )
    end
  end

  test "pagination keeps active filters in links" do
    get catalog_path, params: { category_id: @category.id, search: "Burger", max_price: 20, page: 2 }

    assert_response :success
    assert_includes response.body, '<strong>13</strong> produit'
    assert_includes response.body, "category_id=#{@category.id}"
    assert_includes response.body, "search=Burger"
    assert_includes response.body, "max_price=20"
    assert_includes response.body, "page=1"
  end
end
