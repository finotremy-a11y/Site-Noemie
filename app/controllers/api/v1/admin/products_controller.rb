module Api
  module V1
    module Admin
      class ProductsController < BaseController
        def index
          products = Product.includes(:category).order(updated_at: :desc, id: :desc)

          render json: {
            data: products.map { |product| serialize_product(product) }
          }, status: :ok
        end

        def show
          product = Product.includes(:category, :product_options).find_by(id: params[:id])
          return render_not_found unless product

          render json: {
            data: serialize_product(product, include_options: true)
          }, status: :ok
        end

        def create
          product = Product.new(product_params)

          if product.save
            render json: {
              data: serialize_product(product)
            }, status: :created
          else
            render_validation_error(product)
          end
        end

        def update
          product = Product.find_by(id: params[:id])
          return render_not_found unless product

          previous_price = product.price_cents
          if product.update(product_params)
            record_price_change(product, previous_price)
            render json: {
              data: serialize_product(product)
            }, status: :ok
          else
            render_validation_error(product)
          end
        end

        def destroy
          product = Product.find_by(id: params[:id])
          return render_not_found unless product

          product.destroy!
          head :no_content
        end

        private

        def product_params
          params.require(:product).permit(
            :category_id,
            :name,
            :description,
            :price_cents,
            :currency,
            :active,
            :stock_quantity,
            :image_url,
            :seasonal_start_date,
            :seasonal_end_date,
            badges: []
          )
        end

        def record_price_change(product, previous_price)
          return unless previous_price && previous_price != product.price_cents

          product.product_price_changes.create!(
            old_price_cents: previous_price,
            new_price_cents: product.price_cents,
            reason: params[:price_change_reason],
            changed_by: "admin_api"
          )
        end

        def render_validation_error(record)
          render_error(
            code: "validation_error",
            message: "Parametres invalides.",
            details: { errors: record.errors.full_messages },
            status: :unprocessable_entity
          )
        end

        def render_not_found
          render_error(
            code: "not_found",
            message: "Produit introuvable.",
            status: :not_found
          )
        end

        def serialize_product(product, include_options: false)
          payload = {
            id: product.id,
            category_id: product.category_id,
            name: product.name,
            description: product.description,
            price_cents: product.price_cents,
            currency: product.currency,
            active: product.active,
            stock_quantity: product.stock_quantity,
            image_url: product.image_url,
            badges: product.badges,
            seasonal_start_date: product.seasonal_start_date,
            seasonal_end_date: product.seasonal_end_date,
            updated_at: product.updated_at
          }

          return payload unless include_options

          payload.merge(
            options: product.product_options.map do |option|
              {
                id: option.id,
                name: option.name,
                price_delta_cents: option.price_delta_cents,
                active: option.active
              }
            end
          )
        end
      end
    end
  end
end
