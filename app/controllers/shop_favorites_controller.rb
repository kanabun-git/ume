class ShopFavoritesController < ApplicationController
  before_action :authenticate_member!

  def create
    shop = ::Shop.visible.find(params[:shop_id])
    current_member.shop_favorites.find_or_create_by!(shop: shop)
    redirect_back fallback_location: shop_path(shop), notice: "お気に入り店舗に追加しました。"
  end

  def destroy
    current_member.shop_favorites.find_by(shop_id: params[:shop_id])&.destroy
    redirect_back fallback_location: root_path, notice: "お気に入り店舗から削除しました。"
  end
end
