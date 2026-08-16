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
  ].freeze
  # /shop_inquiries stays open even during maintenance so the maintenance
  # page's "サイト掲載のお問い合わせ" banner/link (see maintenance/show.html.erb)
  # actually works instead of bouncing back to itself.

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    if maintenance_mode? && !allowed_path?(request.path)
      return render_maintenance_page
    end

    @app.call(env)
  end

  private

  def allowed_path?(path)
    ALLOWED_PATH_PREFIXES.any? { |prefix| path == prefix || path.start_with?("#{prefix}/") }
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
