module Admin
  class ShopVisitsController < BaseController
    before_action :set_shop_membership

    def create
      @shop_membership.record_visit!(
        visited_on: visit_params[:visited_on].presence || Date.current,
        points_earned: visit_params[:points_earned].to_i,
        memo: visit_params[:memo]
      )
      redirect_to admin_shop_shop_membership_path(@shop, @shop_membership), notice: "利用履歴を記録しました。"
    rescue ActiveRecord::RecordInvalid
      redirect_to admin_shop_shop_membership_path(@shop, @shop_membership), alert: "利用履歴の記録に失敗しました。"
    end

    private

    def set_shop_membership
      @shop = ::Shop.find(params[:shop_id])
      @shop_membership = @shop.shop_memberships.find(params[:shop_membership_id])
      authorize @shop_membership, :update?
    end

    def visit_params
      params.require(:shop_visit).permit(:visited_on, :points_earned, :memo)
    end
  end
end
