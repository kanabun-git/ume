module Admin
  class AnalyticsController < BaseController
    RANGE_DAYS = 30

    def index
      @range_days = RANGE_DAYS
      @range_start = Date.current - (RANGE_DAYS - 1)
      @range_end = Date.current
      @dates = (@range_start..@range_end).to_a
      @page_type = %w[cast page].include?(params[:page_type]) ? params[:page_type] : "shop"

      case @page_type
      when "cast"
        @selected_cast = ::Cast.find(params[:cast_id]) if params[:cast_id].present?

        scope = ::CastDailyView.where(view_date: @range_start..@range_end)
        scope = scope.where(cast: @selected_cast) if @selected_cast
        @daily_totals = scope.group(:view_date).sum(:views_count)

        @top_casts = top_records(daily_view_class: ::CastDailyView, association: :cast_id, record_class: ::Cast) unless @selected_cast
      when "page"
        @selected_page_key = ::PageDailyView::PAGE_KEYS.key?(params[:page_key]) ? params[:page_key] : "index"

        @daily_totals = ::PageDailyView.where(view_date: @range_start..@range_end, page_key: @selected_page_key)
          .group(:view_date).sum(:views_count)

        @page_totals = ::PageDailyView::PAGE_KEYS.keys.index_with do |key|
          ::PageDailyView.where(view_date: @range_start..@range_end, page_key: key).sum(:views_count)
        end
      else
        @selected_shop = ::Shop.find(params[:shop_id]) if params[:shop_id].present?

        scope = ::ShopDailyView.where(view_date: @range_start..@range_end)
        scope = scope.where(shop: @selected_shop) if @selected_shop
        @daily_totals = scope.group(:view_date).sum(:views_count)

        @top_shops = top_records(daily_view_class: ::ShopDailyView, association: :shop_id, record_class: ::Shop) unless @selected_shop
      end
    end

    private

    def top_records(daily_view_class:, association:, record_class:)
      totals = daily_view_class.where(view_date: @range_start..@range_end).group(association).sum(:views_count)
      top = totals.sort_by { |_, count| -count }.first(10)
      records_by_id = record_class.where(id: top.map(&:first)).index_by(&:id)
      top.filter_map { |id, count| [records_by_id[id], count] if records_by_id[id] }
    end
  end
end
