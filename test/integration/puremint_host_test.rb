require "test_helper"

# The corporate site is meant to be its own site (www.puremint.jp/corporate),
# not a second door into the portal. Two mechanisms make that true, and this
# covers both:
#
#   * config/routes.rb -- /corporate only resolves on PUREMINT_HOST
#   * PuremintHostMiddleware -- on that host, nothing *but* /corporate (plus
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

  test "the corporate site only resolves on the configured host" do
    with_puremint_host("puremint.example.test") do
      host! "www.example.com"
      get "/corporate"
      assert_response :not_found

      host! "puremint.example.test"
      get "/corporate"
      assert_response :success
    end
  end

  test "the portal itself, including its Devise login, is not served on the puremint host" do
    with_puremint_host("puremint.example.test") do
      host! "puremint.example.test"

      ["/", "/shops", "/admin", "/shop_admin", "/cast", "/users/sign_in"].each do |path|
        get path
        assert_response :not_found, "#{path} must not be reachable on the puremint host"
      end
    end
  end

  test "the corporate site carries no portal branding" do
    with_puremint_host("puremint.example.test") do
      host! "puremint.example.test"

      get "/corporate"

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
