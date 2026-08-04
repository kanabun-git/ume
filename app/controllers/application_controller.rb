class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pundit::Authorization
  include AttachesImages

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  before_action :configure_permitted_parameters, if: :devise_controller?

  def after_sign_in_path_for(resource)
    case resource
    when User
      resource.platform_admin? ? admin_root_path : resource.shop_admin? ? shop_admin_root_path : cast_root_path
    when Member
      member_root_path
    else
      super
    end
  end

  private

  def user_not_authorized
    flash[:alert] = "この操作を行う権限がありません。"
    redirect_to(request.referer || root_path)
  end

  # Devise's default sign_up/account_update params only permit
  # email/password — :name is app-specific (used by both User and Member),
  # so it needs to be added explicitly or every registration/edit 422s.
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end
