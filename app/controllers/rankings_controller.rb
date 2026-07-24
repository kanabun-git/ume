class RankingsController < ApplicationController
  def index
    @shops = Shop.ranked.page(params[:page])
  end
end
