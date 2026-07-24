module CastPortal
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_cast_role!
    layout "cast"

    private

    def require_cast_role!
      return if current_user.cast?

      flash[:alert] = "キャスト専用のページです。"
      redirect_to root_path
    end

    def current_cast_profile
      current_user.cast_profile
    end
  end
end
