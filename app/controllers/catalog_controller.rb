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
      # sanitize_sql_like escapes LIKE wildcards (%, _) in the search term;
      # the value is passed as a named bind parameter — no SQL injection risk.
      sanitized = ActiveRecord::Base.sanitize_sql_like(query_params[:search].to_s.downcase)
      @products = @products.where(
        "LOWER(name) LIKE :q OR LOWER(description) LIKE :q",
        q: "%#{sanitized}%"
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
