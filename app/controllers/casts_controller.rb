class CastsController < ApplicationController
  def show
    @cast = Cast.visible.find(params[:id])
    @shop = @cast.shop
    @diary_entries = @cast.diary_entries.visible.limit(10)
  end
end
