module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_platform_admin_role!
    layout "admin"

    private

    def require_platform_admin_role!
      return if current_user.platform_admin?

      flash[:alert] = "運営者専用のページです。"
      redirect_to root_path
    end
  end
end
