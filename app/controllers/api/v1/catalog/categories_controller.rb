module Api
  module V1
    module Catalog
      class CategoriesController < BaseController
        def index
          categories = Category.active.ordered

          render json: {
            data: categories.map { |category| serialize_category(category) }
          }, status: :ok
        end

        private

        def serialize_category(category)
          {
            id: category.id,
            name: category.name,
            slug: category.slug,
            position: category.position
          }
        end
      end
    end
  end
end
