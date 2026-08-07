module ShopAdmin
  class CouponUsagesController < BaseController
    before_action :set_coupon

    def index
      @usages = @coupon.coupon_usages
    end

    # Lets the shop admin log an in-person redemption (e.g. a walk-in
    # customer who mentioned the coupon) alongside the net-reservation
    # clicks tracked automatically from the public coupon page.
    def create
      @coupon.coupon_usages.create!(usage_type: :manual)
      redirect_to shop_admin_coupon_usages_path(@coupon), notice: "利用実績を記録しました。"
    end

    private

    def set_coupon
      @coupon = current_shop.coupons.find(params[:coupon_id])
      authorize @coupon, :update?
    end
  end
end
