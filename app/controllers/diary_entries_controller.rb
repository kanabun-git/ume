class DiaryEntriesController < ApplicationController
  def index
    @areas = Area.all
    @genres = Genre.all
    @diary_entries = DiaryEntry.visible
      .joins(cast: :shop).merge(Cast.visible).merge(Shop.visible)
      .includes(cast: { shop: [:area, :genre] })
    @diary_entries = @diary_entries.where(shops: { area_id: params[:area_id] }) if params[:area_id].present?
    @diary_entries = @diary_entries.where(shops: { genre_id: params[:genre_id] }) if params[:genre_id].present?
    @diary_entries = @diary_entries.page(params[:page])
  end
end
