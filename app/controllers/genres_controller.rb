class GenresController < ApplicationController
  def show
    @genre = Genre.find_by!(slug: params[:slug])
    @shops = Shop.visible.where(genre_id: @genre.id).page(params[:page])
  end
end
