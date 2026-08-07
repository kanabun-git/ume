class ShopMembershipsController < ApplicationController
  before_action :authenticate_member!

  def create
    shop = ::Shop.visible.find(params[:shop_id])

    unless current_member.phone_verified?
      redirect_to new_member_phone_verification_path(return_to: shop_path(shop)),
        alert: "店舗会員証への登録にはSMS認証が必要です。"
      return
    end

    membership = current_member.shop_memberships.find_or_create_by!(shop: shop)
    redirect_to member_shop_membership_path(membership), notice: "店舗会員証に登録しました。"
  end
end
