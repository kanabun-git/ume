module Admin
  class CouponsController < BaseController
    before_action :set_shop

    def index
      @coupons = @shop.coupons
    end

    def show
      @coupon = @shop.coupons.find(params[:id])
      authorize @coupon
      @usages = @coupon.coupon_usages
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:shop_id])
    end
  end
end
