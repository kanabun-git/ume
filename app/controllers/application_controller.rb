class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def after_sign_in_path_for(resource)
    case resource
    when User
      resource.platform_admin? ? admin_root_path : resource.shop_admin? ? shop_admin_root_path : cast_root_path
    else
      super
    end
  end

  private

  def user_not_authorized
    flash[:alert] = "この操作を行う権限がありません。"
    redirect_to(request.referer || root_path)
  end
end
