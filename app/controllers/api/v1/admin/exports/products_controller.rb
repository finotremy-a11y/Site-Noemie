module Api
  module V1
    module Admin
      module Exports
        class ProductsController < BaseController
          def csv
            products = Product.includes(:category)
            products = apply_filters(products)
            products = apply_sort(products)

            csv_content = generate_products_csv(products)

            send_data csv_content,
                      filename: "products-#{Date.today}.csv",
                      type: "text/csv"
          end

          private

          def apply_filters(scope)
            filtered = scope

            if params[:q].present?
              query = "%#{params[:q].to_s.strip.downcase}%"
              filtered = filtered.where("LOWER(name) LIKE :query OR LOWER(description) LIKE :query", query: query)
            end

            filtered = filtered.where(category_id: params[:category_id]) if params[:category_id].present?

            unless params[:active].nil? || params[:active].to_s.blank?
              active = ActiveModel::Type::Boolean.new.cast(params[:active])
              filtered = filtered.where(active: active)
            end

            if params[:low_stock].to_s == "1"
              filtered = filtered.where("stock_quantity <= ?", 5)
            end

            filtered
          end

          def apply_sort(scope)
            allowed_columns = %w[updated_at created_at name price_cents stock_quantity active]
            requested_column = params[:sort].to_s
            requested_direction = params[:direction].to_s

            column = allowed_columns.include?(requested_column) ? requested_column : "updated_at"
            direction = %w[asc desc].include?(requested_direction) ? requested_direction : "desc"

            scope.order(column => direction)
          end

          def generate_products_csv(products)
            require "csv"

            CSV.generate(headers: true) do |csv|
              csv << [ "SKU", "Nom", "Catégorie", "Prix (€)", "Stock", "Statut", "Créé le" ]

              products.each do |product|
                csv << [
                  product.sku,
                  product.name,
                  product.category&.name || "N/A",
                  "%.2f" % (product.price_cents / 100.0),
                  product.stock_quantity,
                  product.is_available ? "Actif" : "Inactif",
                  product.created_at.strftime("%d/%m/%Y")
                ]
              end
            end
          end
        end
      end
    end
  end
end
