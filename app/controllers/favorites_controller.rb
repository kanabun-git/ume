class FavoritesController < ApplicationController
  before_action :authenticate_member!

  def create
    cast = ::Cast.visible.joins(:shop).merge(::Shop.visible).find(params[:cast_id])
    current_member.favorites.find_or_create_by!(cast: cast)
    redirect_back fallback_location: cast_path(cast), notice: "お気に入りに追加しました。"
  end

  def destroy
    current_member.favorites.find_by(cast_id: params[:cast_id])&.destroy
    redirect_back fallback_location: root_path, notice: "お気に入りから削除しました。"
  end
end
