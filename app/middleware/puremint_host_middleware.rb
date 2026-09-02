# Keeps the corporate site (PUREMINT_HOST, e.g. www.puremint.jp) looking and
# behaving like its own separate site rather than a second door into the
# portal -- same idea as MailAdminHostMiddleware for www.kanabun.tech.
#
# config/routes.rb already makes the corporate pages resolve *only* on that
# host, mounted at the root path (no "/corporate" prefix) there so
# https://www.puremint.jp/ itself is the corporate top page; this is the
# other half: on that host, nothing but those pages (plus static assets)
# resolves at all, so the portal's public pages and its /admin, /shop_admin,
# /cast, /users (Devise) back offices are simply not there.
#
# Does nothing when PUREMINT_HOST is unset (development, test, and any
# deployment that hasn't set up the separate domain yet) -- there the
# corporate pages stay under "/corporate" alongside the portal.
class PuremintHostMiddleware
  ALLOWED_PATHS = %w[/].freeze
  ALLOWED_PATH_PREFIXES = %w[
    /company
    /business
    /access
    /inquiries
    /assets
    /rails
    /up
  ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    return not_found if puremint_host?(request) && !allowed_path?(request.path)

    @app.call(env)
  end

  private

  def puremint_host?(request)
    ENV["PUREMINT_HOST"].present? && request.host == ENV["PUREMINT_HOST"]
  end

  def allowed_path?(path)
    ALLOWED_PATHS.include?(path) ||
      ALLOWED_PATH_PREFIXES.any? { |prefix| path == prefix || path.start_with?("#{prefix}/") }
  end

  def not_found
    [404, { "Content-Type" => "text/plain; charset=utf-8" }, ["Not Found"]]
  end
end
