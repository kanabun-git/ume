module Admin
  class CouponsController < BaseController
    before_action :set_shop
    before_action :set_coupon, only: [:show, :edit, :update, :destroy]

    def index
      @coupons = @shop.coupons
    end

    def show
      @usages = @coupon.coupon_usages
    end

    def new
      @coupon = @shop.coupons.build(valid_from: Date.current)
      @casts = @shop.casts.visible
      authorize @coupon
    end

    def create
      @coupon = @shop.coupons.build(coupon_params)
      authorize @coupon

      if @coupon.save
        redirect_to admin_shop_coupons_path(@shop), notice: "クーポンを登録しました。"
      else
        @casts = @shop.casts.visible
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @casts = @shop.casts.visible
    end

    def update
      if @coupon.update(coupon_params)
        redirect_to admin_shop_coupons_path(@shop), notice: "クーポンを更新しました。"
      else
        @casts = @shop.casts.visible
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @coupon.destroy
      redirect_to admin_shop_coupons_path(@shop), notice: "クーポンを削除しました。"
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:shop_id])
    end

    def set_coupon
      @coupon = @shop.coupons.find(params[:id])
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
