class HomeController < ApplicationController
  def index
    @areas = Area.where(parent_id: nil).active_region.includes(:children)
    @prefectures_by_region = @areas.group_by(&:region)
    @genres = Genre.all
    @ranked_shops = Shop.ranked.limit(10)
    @latest_diary_entries = DiaryEntry.visible.limit(8)
    @latest_videos = ShopPageBlock.with_video.visible
      .joins(:shop).merge(Shop.visible)
      .includes(shop: :genre)
      .reorder(created_at: :desc).limit(4)
  end
end
