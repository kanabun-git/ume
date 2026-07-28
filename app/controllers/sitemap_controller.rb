class SitemapController < ApplicationController
  def index
    @areas = Area.all
    @genres = Genre.all
    @shops = Shop.visible
    @casts = Cast.active.joins(:shop).merge(Shop.visible)

    respond_to do |format|
      format.xml
    end
  end
end
