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

    # Content fields only — status/plan/area/genre, and editorial fields
    # (chain_name/editor_review), go through the platform admin back office
    # (see Admin::ShopsController).
    def shop_params
      params.require(:shop).permit(
        :catch_copy, :description, :address, :phone, :business_hours, :time_display_format,
        :price_note, :transportation_fee_note, :coverage_area_note,
        :coupon_description, :recruiting_message,
        :online_reservation, :visit_point_program, :coupon_available,
        :event_ongoing, :recruiting_cast, :recruiting_staff,
        photos: []
      )
    end
  end
end
