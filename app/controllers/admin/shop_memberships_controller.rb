module Admin
  class ShopMembershipsController < BaseController
    before_action :set_shop

    def index
      @shop_memberships = @shop.shop_memberships.includes(:member)
    end

    def show
      @shop_membership = @shop.shop_memberships.find(params[:id])
      authorize @shop_membership
      @shop_visits = @shop_membership.shop_visits
      @shop_point_transactions = @shop_membership.shop_point_transactions
      @shop_member_benefit_grants = @shop_membership.shop_member_benefit_grants.includes(:shop_member_benefit)
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:shop_id])
    end
  end
end
