module Admin
  class AnalyticsController < BaseController
    RANGE_DAYS = 30

    def index
      @range_days = RANGE_DAYS
      @range_start = Date.current - (RANGE_DAYS - 1)
      @range_end = Date.current
      @dates = (@range_start..@range_end).to_a

      @selected_shop = ::Shop.find(params[:shop_id]) if params[:shop_id].present?

      scope = ::ShopDailyView.where(view_date: @range_start..@range_end)
      scope = scope.where(shop: @selected_shop) if @selected_shop
      @daily_totals = scope.group(:view_date).sum(:views_count)

      unless @selected_shop
        totals_by_shop_id = ::ShopDailyView.where(view_date: @range_start..@range_end)
          .group(:shop_id).sum(:views_count)
        top = totals_by_shop_id.sort_by { |_, count| -count }.first(10)
        shops_by_id = ::Shop.where(id: top.map(&:first)).index_by(&:id)
        @top_shops = top.filter_map { |shop_id, count| [shops_by_id[shop_id], count] if shops_by_id[shop_id] }
      end
    end
  end
end
