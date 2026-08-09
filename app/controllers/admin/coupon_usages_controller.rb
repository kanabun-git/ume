module Admin
  class CouponUsagesController < BaseController
    before_action :set_coupon

    def create
      @coupon.coupon_usages.create!(usage_type: :manual)
      redirect_to admin_shop_coupon_path(@shop, @coupon), notice: "利用実績を記録しました。"
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:shop_id])
    end

    def set_coupon
      set_shop
      @coupon = @shop.coupons.find(params[:coupon_id])
      authorize @coupon, :update?
    end
  end
end
