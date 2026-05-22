module Admin
  class BusinessSettingsController < BaseController
    def show
      @business_setting = BusinessSetting.current
    end

    def update
      @business_setting = BusinessSetting.current

      if @business_setting.update(business_setting_params)
        redirect_to admin_business_settings_path, notice: "Parametres metier mis a jour."
      else
        flash.now[:alert] = @business_setting.errors.full_messages.join(", ")
        render :show, status: :unprocessable_entity
      end
    end

    private

    def business_setting_params
      params.require(:business_setting).permit(
        :delivery_min_order_cents,
        :tier_one_max_km,
        :tier_one_fee_cents,
        :tier_two_max_km,
        :tier_two_fee_cents,
        :vat_rate
      )
    end
  end
end
