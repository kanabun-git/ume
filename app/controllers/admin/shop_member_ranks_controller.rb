module Admin
  class ShopMemberRanksController < BaseController
    def index
      @shop = ::Shop.find(params[:shop_id])
      @shop_member_ranks = @shop.shop_member_ranks.includes(:shop_member_benefits)
    end
  end
end
