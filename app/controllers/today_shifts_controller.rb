class TodayShiftsController < ApplicationController
  def index
    @areas = Area.all
    @genres = Genre.all
    @shifts = Shift.scheduled
      .where(work_date: Date.current)
      .joins(cast: :shop).merge(Cast.visible).merge(Shop.visible)
      .includes(cast: { shop: :genre })
    @shifts = @shifts.where(shops: { area_id: params[:area_id] }) if params[:area_id].present?
    @shifts = @shifts.where(shops: { genre_id: params[:genre_id] }) if params[:genre_id].present?
    @shifts = @shifts.reorder(:start_time).page(params[:page])
  end
end
