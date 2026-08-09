module MemberPortal
  class MypageController < BaseController
    def show
      @favorite_casts = current_member.favorite_casts
        .joins(:shop).merge(::Shop.visible).merge(::Cast.visible)
        .includes(:shop)
        .order(:name)

      cast_ids = @favorite_casts.map(&:id)
      @today_shifts_by_cast_id = ::Shift.scheduled.where(work_date: Date.current, cast_id: cast_ids).index_by(&:cast_id)
      @latest_diary_entry_by_cast_id = ::DiaryEntry.visible.where(cast_id: cast_ids).group_by(&:cast_id).transform_values(&:first)

      @favorite_shops = current_member.favorite_shops.visible.includes(:area, :genre).order(:name)
      @shop_memberships = current_member.shop_memberships.includes(:shop)
      @membership_card_image = current_member.membership_card_image
    end
  end
end
