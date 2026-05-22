module Api
  module V1
    module Catalog
      class ProductsController < BaseController
        DEFAULT_PAGE = 1
        DEFAULT_LIMIT = 12
        MAX_LIMIT = 50

        def index
          scope = Product.includes(:category, :product_options).active.in_season
          scope = apply_filters(scope)
          scope = apply_sort(scope)

          page = normalize_page(params[:page])
          limit = normalize_limit(params[:limit])
          total = scope.count
          products = scope.offset((page - 1) * limit).limit(limit)

          render json: {
            data: products.map { |product| serialize_product(product) },
            meta: {
              page: page,
              limit: limit,
              total: total
            }
          }, status: :ok
        end

        def show
          product = Product.includes(:category, :product_options).active.in_season.find_by(id: params[:id])
          return render_not_found unless product

          render json: {
            data: serialize_product(product)
          }, status: :ok
        end

        private

        def apply_filters(scope)
          scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

          if params[:q].present?
            term = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"
            scope = scope.where("products.name ILIKE ? OR products.description ILIKE ?", term, term)
          end

          if params[:available].present?
            available = ActiveModel::Type::Boolean.new.cast(params[:available])
            scope = available ? scope.where("stock_quantity > 0") : scope
          end

          scope = scope.where("price_cents >= ?", params[:min_price_cents].to_i) if params[:min_price_cents].present?
          scope = scope.where("price_cents <= ?", params[:max_price_cents].to_i) if params[:max_price_cents].present?
          scope
        end

        def apply_sort(scope)
          case params[:sort]
          when "price_asc"
            scope.order(price_cents: :asc, id: :asc)
          when "price_desc"
            scope.order(price_cents: :desc, id: :desc)
          when "name_asc"
            scope.order(name: :asc, id: :asc)
          when "newest"
            scope.order(created_at: :desc, id: :desc)
          else
            scope.order(updated_at: :desc, id: :desc)
          end
        end

        def normalize_page(value)
          page = value.to_i
          page.positive? ? page : DEFAULT_PAGE
        end

        def normalize_limit(value)
          limit = value.to_i
          limit = DEFAULT_LIMIT unless limit.positive?
          [ limit, MAX_LIMIT ].min
        end

        def render_not_found
          render_error(
            code: "not_found",
            message: "Produit introuvable.",
            status: :not_found
          )
        end

        def serialize_product(product)
          {
            id: product.id,
            name: product.name,
            description: product.description,
            price_cents: product.price_cents,
            currency: product.currency,
            active: product.active,
            stock_quantity: product.stock_quantity,
            image_url: product.image_url,
            badges: product.badges,
            category: {
              id: product.category.id,
              name: product.category.name,
              slug: product.category.slug
            },
            options: product.product_options.active.map do |option|
              {
                id: option.id,
                name: option.name,
                price_delta_cents: option.price_delta_cents
              }
            end
          }
        end
      end
    end
  end
end
