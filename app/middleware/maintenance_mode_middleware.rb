# Shows a "under maintenance" page for public-facing requests while the
# platform admin has maintenance mode switched on (see Admin::SettingsController).
# Back-office areas stay reachable throughout so an admin can log in and
# switch it back off, and so shop admins/casts can keep working.
class MaintenanceModeMiddleware
  ALLOWED_PATH_PREFIXES = %w[
    /admin
    /shop_admin
    /cast
    /mailadmin
    /users
    /assets
    /rails
    /up
    /icon.png
    /icon.svg
    /manifest.json
    /service-worker
    /shop_inquiries
    /outreach
  ].freeze
  # /shop_inquiries stays open even during maintenance so the maintenance
  # page's "サイト掲載のお問い合わせ" banner/link (see maintenance/show.html.erb)
  # actually works instead of bouncing back to itself. /outreach stays open
  # too, so a 営業メール link clicked during maintenance still records the
  # click and reaches /shop_inquiries instead of dead-ending on this page.

  # /shops/:id and /casts/:id are the public URLs shop_admin's "プレビューを
  # 見る" links point to (see ApplicationController#can_preview_shop?) --
  # they stay blocked by maintenance mode for everyone else, but a signed-in
  # platform admin or the shop's own shop admin needs to keep reaching them
  # (e.g. to demo a shop's design) even while the rest of the public site is
  # down.
  PREVIEWABLE_PATH_PATTERN = %r{\A/(shops|casts)/(\d+)(?:/|\z)}

  # PUREMINT_HOST(コーポレートサイト)、MAIL_ADMIN_HOST(メールアドレス管理
  # 画面)、VINTAGE_HOST(古着ブランド判定ツール)は、たまたま同じアプリに
  # 同居しているだけの別サイト(PuremintHostMiddleware /
  # MailAdminHostMiddleware / config/routes.rb を参照)。ポータルを
  # メンテナンスにしたことは、これらのサイトについては何も意味しないので、
  # そのまま動かし続ける -- 運営管理画面でチェックを入れた人は、
  # fuzoku-zero.com を止めるつもりであって、会社のコーポレートサイトまで
  # 落とすつもりではない。
  SEPARATE_SITE_HOST_ENV_KEYS = %w[PUREMINT_HOST MAIL_ADMIN_HOST VINTAGE_HOST].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    return @app.call(env) if separate_site_host?(request)

    if maintenance_mode? && !allowed_path?(request.path) && !previewable_by_current_user?(env, request.path)
      return render_maintenance_page
    end

    @app.call(env)
  end

  private

  def separate_site_host?(request)
    SEPARATE_SITE_HOST_ENV_KEYS.any? do |key|
      host = ENV[key]
      host.present? && request.host == host
    end
  end

  def allowed_path?(path)
    ALLOWED_PATH_PREFIXES.any? { |prefix| path == prefix || path.start_with?("#{prefix}/") }
  end

  def previewable_by_current_user?(env, path)
    user = env["warden"]&.user(:user)
    return false unless user
    return true if user.platform_admin?
    return false unless user.shop_admin?

    match = PREVIEWABLE_PATH_PATTERN.match(path)
    return false unless match

    shop_id = match[1] == "shops" ? match[2].to_i : ::Cast.where(id: match[2]).pick(:shop_id)
    shop_id.present? && shop_id == user.shop_id
  end

  def maintenance_mode?
    SiteSetting.instance.maintenance_mode?
  rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
    # Table/database not ready yet (e.g. during db:create, asset precompile
    # in CI). Never let maintenance-mode lookup itself take the site down.
    false
  end

  def render_maintenance_page
    setting = SiteSetting.instance
    body = ApplicationController.render(
      template: "maintenance/show",
      layout: false,
      locals: { site_setting: setting }
    )
    [503, { "Content-Type" => "text/html; charset=utf-8", "Retry-After" => "3600" }, [body]]
  end
end
