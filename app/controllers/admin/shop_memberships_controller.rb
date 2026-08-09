module Admin
  class ShopMembershipsController < BaseController
    before_action :set_shop
    before_action :set_shop_membership, only: [:show, :update]

    def index
      @shop_memberships = @shop.shop_memberships.includes(:member)
    end

    def show
      @shop_visits = @shop_membership.shop_visits
      @shop_point_transactions = @shop_membership.shop_point_transactions
      @shop_member_benefit_grants = @shop_membership.shop_member_benefit_grants.includes(:shop_member_benefit)
    end

    def update
      if @shop_membership.update(shop_membership_params)
        redirect_to admin_shop_shop_membership_path(@shop, @shop_membership), notice: "事故歴・注意点を更新しました。"
      else
        redirect_to admin_shop_shop_membership_path(@shop, @shop_membership), alert: "更新に失敗しました。"
      end
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:shop_id])
    end

    def set_shop_membership
      @shop_membership = @shop.shop_memberships.find(params[:id])
      authorize @shop_membership
    end

    def shop_membership_params
      params.require(:shop_membership).permit(:incident_notes, :caution_notes)
    end
  end
end
