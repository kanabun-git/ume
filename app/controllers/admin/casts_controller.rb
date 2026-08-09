module Admin
  class CastsController < BaseController
    before_action :set_shop

    def index
      @casts = @shop.casts
    end

    def show
      @cast = @shop.casts.find(params[:id])
      authorize @cast
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:shop_id])
    end
  end
end
