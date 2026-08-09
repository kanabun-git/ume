module Admin
  class ShopPointRedemptionsController < BaseController
    before_action :set_shop_membership

    def create
      amount = redemption_params[:amount].to_i
      reason = redemption_params[:reason].presence || "ポイント利用"

      if @shop_membership.redeem_points!(amount, reason: reason)
        redirect_to admin_shop_shop_membership_path(@shop, @shop_membership), notice: "#{amount}ポイントを利用済みにしました。"
      else
        redirect_to admin_shop_shop_membership_path(@shop, @shop_membership), alert: "ポイント残高が不足しているため利用できません。"
      end
    end

    private

    def set_shop_membership
      @shop = ::Shop.find(params[:shop_id])
      @shop_membership = @shop.shop_memberships.find(params[:shop_membership_id])
      authorize @shop_membership, :update?
    end

    def redemption_params
      params.require(:shop_point_redemption).permit(:amount, :reason)
    end
  end
end
