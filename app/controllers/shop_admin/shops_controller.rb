module ShopAdmin
  class ShopsController < BaseController
    before_action :set_shop

    def edit
      authorize @shop, :update?
    end

    def update
      authorize @shop, :update?

      if @shop.update(shop_params)
        redirect_to shop_admin_root_path, notice: "店舗情報を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_shop
      @shop = current_shop
    end

    # Content fields only — status/plan/area/genre changes go through the
    # platform admin back office (see Admin::ShopsController).
    def shop_params
      params.require(:shop).permit(:catch_copy, :description, :address, :phone, :business_hours, photos: [])
    end
  end
end
