# Keeps the mail address management site (MAIL_ADMIN_HOST, e.g.
# www.kanabun.tech) looking and behaving like its own separate site rather
# than a second door into the portal.
#
# config/routes.rb already makes /mailadmin resolve *only* on that host; this
# is the other half: on that host, nothing but /mailadmin (plus static
# assets) resolves at all, so the portal's public pages and its /admin,
# /shop_admin, /cast, /users (Devise) back offices are simply not there.
# /mailadmin itself is protected by its own Basic auth (see
# MailAdmin::BaseController), not Devise, so no login route needs carving
# out here.
#
# Does nothing when MAIL_ADMIN_HOST is unset (development, test, and any
# deployment that hasn't set up the separate domain yet).
class MailAdminHostMiddleware
  ALLOWED_PATH_PREFIXES = %w[
    /mailadmin
    /assets
    /rails
    /up
  ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    return not_found if mail_admin_host?(request) && !allowed_path?(request.path)

    @app.call(env)
  end

  private

  def mail_admin_host?(request)
    ENV["MAIL_ADMIN_HOST"].present? && request.host == ENV["MAIL_ADMIN_HOST"]
  end

  def allowed_path?(path)
    ALLOWED_PATH_PREFIXES.any? { |prefix| path == prefix || path.start_with?("#{prefix}/") }
  end

  def not_found
    [404, { "Content-Type" => "text/plain; charset=utf-8" }, ["Not Found"]]
  end
end
