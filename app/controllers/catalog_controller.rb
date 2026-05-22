class CatalogController < ApplicationController
  def index
    @page = (params[:page] || 1).to_i
    @per_page = 12

    # Fetch categories
    @categories = Category.where(active: true).order(:position, :name)

    # Build query
    query_params = {}
    query_params[:category_id] = params[:category_id] if params[:category_id].present?
    query_params[:search] = params[:search] if params[:search].present?
    query_params[:min_price] = params[:min_price] if params[:min_price].present?
    query_params[:max_price] = params[:max_price] if params[:max_price].present?

    # Fetch products
    @products = Product.available.includes(:category)
    @products = @products.where(category_id: query_params[:category_id]) if query_params[:category_id]

    if query_params[:search]
      @products = @products.where(
        "LOWER(name) LIKE ? OR LOWER(description) LIKE ?",
        "%#{query_params[:search].downcase}%",
        "%#{query_params[:search].downcase}%"
      )
    end

    if query_params[:min_price]
      @products = @products.where("price_cents >= ?", (query_params[:min_price].to_f * 100).round)
    end

    if query_params[:max_price]
      @products = @products.where("price_cents <= ?", (query_params[:max_price].to_f * 100).round)
    end

    @total_count = @products.count
    @total_pages = (@total_count.to_f / @per_page).ceil

    @products = @products.offset((@page - 1) * @per_page).limit(@per_page)
  end

  def show
    @product = Product.includes(:category, :product_options).find(params[:id])
    @reviews = Review.approved.where(product_id: @product.id).order(created_at: :desc).limit(6) if Review.column_names.include?("product_id")
    @related_products = Product.where(category: @product.category)
                                .where.not(id: @product.id)
                                .available
                                .limit(4)
  end
end
