module ShopAdmin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_shop_admin_role!
    layout "shop_admin"

    private

    def require_shop_admin_role!
      return if current_user.shop_admin?

      flash[:alert] = "店舗管理者専用のページです。"
      redirect_to root_path
    end

    def current_shop
      @current_shop ||= current_user.shop
    end
  end
end
