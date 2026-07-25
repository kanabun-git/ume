class HomeController < ApplicationController
  def index
    @areas = Area.where(parent_id: nil).active_region.includes(:children)
    @prefectures_by_region = @areas.group_by(&:region)
    @genres = Genre.all
    @ranked_shops = Shop.ranked.limit(10)
    @latest_diary_entries = DiaryEntry.visible.limit(8)
  end
end
