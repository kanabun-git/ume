require "test_helper"

# The mail address management screen is meant to be its own site
# (www.kanabun.tech/mailadmin), not a second door into the portal. Two
# mechanisms make that true, and this covers both:
#
#   * config/routes.rb -- /mailadmin only resolves on MAIL_ADMIN_HOST
#   * MailAdminHostMiddleware -- on that host, nothing *but* /mailadmin
#     (plus static assets) resolves at all -- not even Devise's /users, since
#     this screen is protected by its own Basic auth, not a Devise session.
#
# Reloads routes around the ENV change and restores both in an `ensure`, the
# same way cast_portal_host_constraint_test.rb does, so nothing leaks into
# other tests in the same parallel worker.
class MailAdminHostTest < ActionDispatch::IntegrationTest
  def with_mail_admin_host(host)
    original = ENV["MAIL_ADMIN_HOST"]
    ENV["MAIL_ADMIN_HOST"] = host
    Rails.application.reload_routes!
    yield
  ensure
    ENV["MAIL_ADMIN_HOST"] = original
    Rails.application.reload_routes!
  end

  test "the management screen only resolves on the configured host" do
    with_mail_admin_host("mailadmin.example.test") do
      host! "www.example.com"
      get "/mailadmin"
      assert_response :not_found

      host! "mailadmin.example.test"
      get "/mailadmin", headers: mail_admin_auth_headers
      assert_response :success
    end
  end

  test "the portal itself, including its Devise login, is not served on the mail admin host" do
    with_mail_admin_host("mailadmin.example.test") do
      host! "mailadmin.example.test"

      ["/", "/shops", "/admin", "/shop_admin", "/cast", "/users/sign_in"].each do |path|
        get path
        assert_response :not_found, "#{path} must not be reachable on the mail admin host"
      end
    end
  end

  test "the management screen carries no portal branding" do
    with_mail_admin_host("mailadmin.example.test") do
      host! "mailadmin.example.test"

      get "/mailadmin", headers: mail_admin_auth_headers

      assert_response :success
      assert_match "メールアドレス管理", response.body
      assert_no_match(/FuzokuZero/, response.body)
    end
  end

  test "without the environment variable everything behaves as before" do
    host! "www.example.com"

    get "/mailadmin", headers: mail_admin_auth_headers
    assert_response :success

    get "/"
    assert_response :success
  end
end
