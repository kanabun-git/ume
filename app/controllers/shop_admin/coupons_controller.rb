module ShopAdmin
  class CouponsController < BaseController
    before_action :set_coupon, only: [:edit, :update, :destroy]

    def index
      @coupons = current_shop.coupons
    end

    def new
      @coupon = current_shop.coupons.build(valid_from: Date.current)
      @casts = current_shop.casts.visible
      authorize @coupon
    end

    def create
      @coupon = current_shop.coupons.build(coupon_params)
      authorize @coupon

      if @coupon.save
        redirect_to shop_admin_coupons_path, notice: "クーポンを登録しました。"
      else
        @casts = current_shop.casts.visible
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @casts = current_shop.casts.visible
    end

    def update
      if @coupon.update(coupon_params)
        redirect_to shop_admin_coupons_path, notice: "クーポンを更新しました。"
      else
        @casts = current_shop.casts.visible
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @coupon.destroy
      redirect_to shop_admin_coupons_path, notice: "クーポンを削除しました。"
    end

    private

    def set_coupon
      @coupon = current_shop.coupons.find(params[:id])
      authorize @coupon
    end

    def coupon_params
      params.require(:coupon).permit(
        :title, :course_name, :regular_price, :discounted_price,
        :valid_from, :valid_until, :conditions, :net_reservation_only, :position,
        :cast_id, :coupon_number
      )
    end
  end
end
