class CouponsController < ApplicationController
  def index
    @areas = Area.all
    @genres = Genre.all
    @shops = Shop.visible.where(coupon_available: true).includes(:area, :genre)
    @shops = @shops.where(area_id: params[:area_id]) if params[:area_id].present?
    @shops = @shops.where(genre_id: params[:genre_id]) if params[:genre_id].present?
    @shops = @shops.page(params[:page])
  end
end
