class CastsController < ApplicationController
  def index
    @areas = Area.all
    @genres = Genre.all
    @casts = Cast.visible.joins(:shop).merge(Shop.visible).includes(shop: [:area, :genre])
    @casts = @casts.where(shops: { area_id: params[:area_id] }) if params[:area_id].present?
    @casts = @casts.where(shops: { genre_id: params[:genre_id] }) if params[:genre_id].present?
    @casts = @casts.where(cup: params[:cup]) if params[:cup].present?
    @casts = @casts.where("casts.age >= ?", params[:min_age]) if params[:min_age].present?
    @casts = @casts.where("casts.age <= ?", params[:max_age]) if params[:max_age].present?
    @casts = @casts.where("casts.height >= ?", params[:min_height]) if params[:min_height].present?
    @casts = @casts.where("casts.height <= ?", params[:max_height]) if params[:max_height].present?
    @casts = @casts.where(is_trial: true) if params[:trial].present?
    if params[:keyword].present?
      keyword = "%#{params[:keyword]}%"
      @casts = @casts.where(
        "casts.name ILIKE :keyword OR casts.alias_name ILIKE :keyword OR casts.catch_copy ILIKE :keyword OR casts.description ILIKE :keyword",
        keyword: keyword
      )
    end
    @casts = @casts.reorder(created_at: :desc).page(params[:page])
  end

  def show
    @cast = Cast.visible.joins(:shop).merge(Shop.visible).find(params[:id])
    @shop = @cast.shop
    @diary_entries = @cast.diary_entries.visible.limit(10)
  end
end
