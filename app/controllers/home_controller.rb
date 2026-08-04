class HomeController < ApplicationController
  def index
    @region = Area::ACTIVE_REGIONS.include?(params[:region]) ? params[:region] : Area::ACTIVE_REGIONS.first
    @areas = Area.where(parent_id: nil, region: @region).includes(:children)
    @genres = Genre.all
    @ranked_shops = Shop.ranked.in_region(@region).limit(10)
    @latest_diary_entries = DiaryEntry.visible.joins(cast: :shop).merge(Shop.visible).merge(Shop.in_region(@region)).limit(8)
    @latest_videos = ShopPageBlock.with_video.visible
      .joins(:shop).merge(Shop.visible).merge(Shop.in_region(@region))
      .includes(shop: :genre)
      .reorder(created_at: :desc).limit(4)
    @today_shifts = Shift.scheduled
      .where(work_date: Date.current)
      .joins(cast: :shop).merge(Cast.visible).merge(Shop.visible).merge(Shop.in_region(@region))
      .includes(cast: :shop)
      .reorder(:start_time).limit(8)
    @coupon_shops = Shop.ranked.in_region(@region).where(coupon_available: true).limit(4)
  end
end
