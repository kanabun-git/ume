module MemberPortal
  class ShopMembershipsController < BaseController
    def index
      @shop_memberships = current_member.shop_memberships.includes(:shop)
    end

    # Shows the member's own visit history, points, and benefit tickets.
    # Deliberately does not expose incident_notes/caution_notes -- those
    # are shop-internal only (see ShopAdmin::ShopMembershipsController).
    def show
      @shop_membership = current_member.shop_memberships.find(params[:id])
      @shop_visits = @shop_membership.shop_visits
      @shop_point_transactions = @shop_membership.shop_point_transactions
      @shop_member_benefit_grants = @shop_membership.shop_member_benefit_grants.includes(:shop_member_benefit)
    end
  end
end
