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
      @shop = @shop_membership.shop
      @shop_visits = @shop_membership.shop_visits
      @shop_point_transactions = @shop_membership.shop_point_transactions
      @shop_member_benefit_grants = @shop_membership.shop_member_benefit_grants.includes(:shop_member_benefit)

      @favorite_casts = current_member.favorite_casts.where(shop: @shop).merge(::Cast.visible).order(:name)
      cast_ids = @favorite_casts.map(&:id)
      @today_shifts_by_cast_id = ::Shift.scheduled.where(work_date: Date.current, cast_id: cast_ids).index_by(&:cast_id)
      @latest_diary_entry_by_cast_id = ::DiaryEntry.visible.where(cast_id: cast_ids).group_by(&:cast_id).transform_values(&:first)

      @present_ticket_entries = current_member.present_ticket_entries.where(present_ticket: @shop.present_tickets).includes(:present_ticket)
    end
  end
end
