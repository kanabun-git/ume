require "test_helper"

# The corporate site is meant to be its own site (https://www.puremint.jp/),
# not a second door into the portal. Two mechanisms make that true, and this
# covers both:
#
#   * config/routes.rb -- the corporate pages only resolve on PUREMINT_HOST,
#     mounted there at the root path (no "/corporate" prefix) so the domain's
#     own "/" is the corporate top page; elsewhere they stay under
#     "/corporate" alongside the portal.
#   * PuremintHostMiddleware -- on that host, nothing *but* those pages (plus
#     static assets) resolves at all
#
# Reloads routes around the ENV change and restores both in an `ensure`, the
# same way mail_admin_host_test.rb does, so nothing leaks into other tests in
# the same parallel worker.
class PuremintHostTest < ActionDispatch::IntegrationTest
  def with_puremint_host(host)
    original = ENV["PUREMINT_HOST"]
    ENV["PUREMINT_HOST"] = host
    Rails.application.reload_routes!
    yield
  ensure
    ENV["PUREMINT_HOST"] = original
    Rails.application.reload_routes!
  end

  test "the corporate top page is served at the bare root on the configured host" do
    with_puremint_host("puremint.example.test") do
      host! "www.example.com"
      get "/"
      assert_match "FuzokuZero", response.body # the portal's own gate page, not the corporate site

      host! "puremint.example.test"
      get "/"
      assert_response :success
      assert_match Corporate::Company::NAME, response.body
    end
  end

  test "the corporate site's other pages resolve without a /corporate prefix on the configured host" do
    with_puremint_host("puremint.example.test") do
      host! "puremint.example.test"

      ["/company", "/business", "/access", "/inquiries/new"].each do |path|
        get path
        assert_response :success, "#{path} should resolve on the puremint host"
      end
    end
  end

  test "the portal itself, including its Devise login, is not served on the puremint host" do
    with_puremint_host("puremint.example.test") do
      host! "puremint.example.test"

      ["/shops", "/admin", "/shop_admin", "/cast", "/users/sign_in", "/corporate"].each do |path|
        get path
        assert_response :not_found, "#{path} must not be reachable on the puremint host"
      end
    end
  end

  test "the corporate site carries no portal branding" do
    with_puremint_host("puremint.example.test") do
      host! "puremint.example.test"

      get "/"

      assert_response :success
      assert_match Corporate::Company::NAME, response.body
      assert_no_match(/FuzokuZero/, response.body)
    end
  end

  test "without the environment variable everything behaves as before" do
    host! "www.example.com"

    get "/corporate"
    assert_response :success

    get "/"
    assert_response :success
  end
end
