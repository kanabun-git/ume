class ShopsController < ApplicationController
  def index
    @shops = Shop.visible.includes(:area, :genre)
    @shops = @shops.where(area_id: params[:area_id]) if params[:area_id].present?
    @shops = @shops.where(genre_id: params[:genre_id]) if params[:genre_id].present?
    @shops = @shops.where("shops.min_price <= ?", params[:max_price]) if params[:max_price].present?
    if params[:cup].present?
      @shops = @shops.where(id: Cast.active.where(cup: params[:cup]).select(:shop_id))
    end
    if params[:keyword].present?
      keyword = "%#{params[:keyword]}%"
      @shops = @shops.where(
        "shops.name ILIKE :keyword OR shops.catch_copy ILIKE :keyword OR shops.description ILIKE :keyword",
        keyword: keyword
      )
    end
    @shops = @shops.page(params[:page])
  end

  def show
    @shop = Shop.visible.find(params[:id])
    @shop.increment!(:view_count)
    ShopDailyView.record!(@shop)
    @casts = @shop.casts.visible
    @reviews = @shop.approved_reviews.limit(10)
    @coupons = @shop.coupons.active
  end
end
