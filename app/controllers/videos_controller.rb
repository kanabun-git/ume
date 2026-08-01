class VideosController < ApplicationController
  def index
    @genres = Genre.all
    @videos = ShopPageBlock.with_video.visible
      .joins(:shop).merge(Shop.visible)
      .includes(shop: :genre)
    @videos = @videos.where(shops: { genre_id: params[:genre_id] }) if params[:genre_id].present?
    @videos = @videos.reorder(created_at: :desc).page(params[:page])
  end
end
