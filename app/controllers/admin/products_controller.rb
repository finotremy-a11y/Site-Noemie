module Admin
  class ProductsController < BaseController
    def index
      @filters = {
        q: params[:q].to_s.strip.presence,
        category_id: params[:category_id].presence,
        active: params[:active].presence,
        low_stock: params[:low_stock] == "1"
      }

      scope = Product.includes(:category)
      if @filters[:q]
        query = "%#{@filters[:q].downcase}%"
        scope = scope.where("LOWER(name) LIKE :query OR LOWER(description) LIKE :query", query: query)
      end
      scope = scope.where(category_id: @filters[:category_id]) if @filters[:category_id]
      unless @filters[:active].nil?
        scope = scope.where(active: ActiveModel::Type::Boolean.new.cast(@filters[:active]))
      end
      scope = scope.where("stock_quantity <= ?", 5) if @filters[:low_stock]

      scope = apply_sort(
        scope,
        allowed_columns: %w[updated_at created_at name price_cents stock_quantity active],
        default_column: "updated_at"
      )

      @categories = Category.ordered
      @products = paginate_scope(scope)
    end

    def show
      @product = Product.includes(:category, :product_options, :product_price_changes).find(params[:id])
    end

    def new
      @product = Product.new(currency: "EUR", active: true)
      load_categories
    end

    def create
      @product = Product.new(product_params)
      @product.badges = normalize_badges(params.dig(:product, :badges_text))

      if @product.save
        redirect_to admin_product_path(@product), notice: "Produit cree avec succes."
      else
        load_categories
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @product = Product.find(params[:id])
      load_categories
    end

    def update
      @product = Product.find(params[:id])
      previous_price = @product.price_cents

      @product.assign_attributes(product_params)
      @product.badges = normalize_badges(params.dig(:product, :badges_text))

      if @product.save
        track_price_change!(@product, previous_price)
        redirect_to admin_product_path(@product), notice: "Produit mis a jour."
      else
        load_categories
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      product = Product.find(params[:id])
      product.destroy!
      redirect_to admin_products_path, notice: "Produit supprime."
    end

    def bulk_update
      ids = Array(params[:product_ids]).map(&:to_i).uniq
      action = params.dig(:bulk, :action).to_s

      if ids.empty?
        redirect_to admin_products_path(request.query_parameters), alert: "Selectionnez au moins un produit."
        return
      end

      products = Product.where(id: ids)
      updated = case action
      when "activate"
                  products.update_all(active: true, updated_at: Time.current)
      when "deactivate"
                  products.update_all(active: false, updated_at: Time.current)
      else
                  0
      end

      if updated.zero?
        redirect_to admin_products_path(request.query_parameters), alert: "Action bulk invalide."
      else
        message = action == "activate" ? "produit(s) active(s)." : "produit(s) desactive(s)."
        redirect_to admin_products_path(request.query_parameters), notice: "#{updated} #{message}"
      end
    end

    private

    def product_params
      params.require(:product).permit(
        :name,
        :description,
        :price_cents,
        :currency,
        :active,
        :stock_quantity,
        :image_url,
        :category_id,
        :seasonal_start_date,
        :seasonal_end_date
      )
    end

    def load_categories
      @categories = Category.ordered
    end

    def normalize_badges(raw)
      raw.to_s.split(",").map(&:strip).reject(&:blank?).uniq
    end

    def track_price_change!(product, previous_price)
      return if previous_price == product.price_cents

      ProductPriceChange.create!(
        product: product,
        old_price_cents: previous_price,
        new_price_cents: product.price_cents,
        reason: "Mise a jour admin web",
        changed_by: current_user.email
      )
    end
  end
end
