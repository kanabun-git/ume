class ShopsController < ApplicationController
  def index
    @shops = Shop.visible.includes(:area, :genre)
    @shops = @shops.where(area_id: params[:area_id]) if params[:area_id].present?
    @shops = @shops.where(genre_id: params[:genre_id]) if params[:genre_id].present?
    @shops = @shops.page(params[:page])
  end

  def show
    @shop = Shop.visible.find(params[:id])
    @shop.increment!(:view_count)
    @casts = @shop.casts.visible
    @reviews = @shop.approved_reviews.limit(10)
  end
end
