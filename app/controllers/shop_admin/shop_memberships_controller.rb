module ShopAdmin
  class ShopMembershipsController < BaseController
    before_action :set_shop_membership, only: [:show, :update]

    def index
      @shop_memberships = current_shop.shop_memberships.includes(:member)
    end

    # Bulk-prints every active cast's check-in QR business card at once, so
    # a shop can hand a stack of A-One card stock to a printer instead of
    # downloading each cast's card one at a time (see CastPortal::CheckInQrController#pdf).
    def check_in_cards
      pdf = CastBusinessCardPdf.for_casts(current_shop.casts.visible, base_url: request.base_url)
      send_data pdf, filename: "check_in_cards_#{current_shop.id}.pdf", type: "application/pdf", disposition: "inline"
    end

    def show
      @shop_visits = @shop_membership.shop_visits
      @shop_point_transactions = @shop_membership.shop_point_transactions
      @shop_member_benefit_grants = @shop_membership.shop_member_benefit_grants.includes(:shop_member_benefit)
    end

    # Records the shop-only incident history / cautions for this member --
    # never exposed on the member_portal side.
    def update
      if @shop_membership.update(shop_membership_params)
        redirect_to shop_admin_shop_membership_path(@shop_membership), notice: "事故歴・注意点を更新しました。"
      else
        redirect_to shop_admin_shop_membership_path(@shop_membership), alert: "更新に失敗しました。"
      end
    end

    private

    def set_shop_membership
      @shop_membership = current_shop.shop_memberships.find(params[:id])
      authorize @shop_membership
    end

    def shop_membership_params
      params.require(:shop_membership).permit(:incident_notes, :caution_notes)
    end
  end
end
