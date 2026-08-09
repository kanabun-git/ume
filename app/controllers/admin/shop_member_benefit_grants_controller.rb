module Admin
  class ShopMemberBenefitGrantsController < BaseController
    before_action :set_shop_membership

    def mark_used
      grant = @shop_membership.shop_member_benefit_grants.find(params[:id])
      grant.mark_used!
      redirect_to admin_shop_shop_membership_path(@shop, @shop_membership), notice: "特典を利用済みにしました。"
    end

    private

    def set_shop_membership
      @shop = ::Shop.find(params[:shop_id])
      @shop_membership = @shop.shop_memberships.find(params[:shop_membership_id])
      authorize @shop_membership, :update?
    end
  end
end
