class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pundit::Authorization
  include AttachesImages

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  before_action :configure_permitted_parameters, if: :devise_controller?

  # Controllers under CastPortal::BaseController set their own explicit
  # `layout "cast"` (which always wins over this), so this only affects
  # pages with no layout of their own -- chiefly Devise's shared
  # sign_in/password screens. When those are opened on the dedicated,
  # unbranded cast portal domain (see config/routes.rb's CAST_PORTAL_HOST
  # constraint), swap in the same neutral shell so a cast member never sees
  # the site's real branding, even before logging in.
  layout :resolve_layout
  helper_method :discreet_cast_portal_host?

  # Lets a shop's own admin (or a platform admin) view its public-facing
  # page/cast pages even while the shop is unapproved or unpublished --
  # the same shop_path/cast_path used by shop_admin's "プレビューを見る"
  # links, so a shop under construction has one URL that just becomes
  # public once actually published instead of a separate preview URL.
  def can_preview_shop?(shop)
    return false unless current_user

    current_user.platform_admin? || (current_user.shop_admin? && current_user.shop_id == shop.id)
  end
  helper_method :can_preview_shop?

  def after_sign_in_path_for(resource)
    case resource
    when User
      resource.platform_admin? ? admin_root_path : resource.shop_admin? ? shop_admin_root_path : cast_root_path
    when Member
      pending_token = session.delete(:pending_cast_check_in_token)
      pending_token.present? ? cast_check_in_path(pending_token) : member_root_path
    else
      super
    end
  end

  private

  def resolve_layout
    "cast_portal_public" if discreet_cast_portal_host?
  end

  def discreet_cast_portal_host?
    ENV["CAST_PORTAL_HOST"].present? && request.host == ENV["CAST_PORTAL_HOST"]
  end

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
