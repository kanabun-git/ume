require "test_helper"

# The mail address management screen is meant to be its own site
# (www.kanabun.tech/mailadmin), not a second door into the portal. Two
# mechanisms make that true, and this covers both:
#
#   * config/routes.rb -- /mailadmin only resolves on MAIL_ADMIN_HOST
#   * MailAdminHostMiddleware -- on that host, nothing *but* /mailadmin
#     (plus login and assets) resolves at all
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
      get "/mailadmin"
      assert_response :redirect # to the sign-in screen
    end
  end

  test "the portal itself is not served on the mail admin host" do
    with_mail_admin_host("mailadmin.example.test") do
      host! "mailadmin.example.test"

      ["/", "/shops", "/admin", "/shop_admin", "/cast"].each do |path|
        get path
        assert_response :not_found, "#{path} must not be reachable on the mail admin host"
      end
    end
  end

  test "signing in stays reachable on the mail admin host and lands on the management screen" do
    admin = create_user(role: :platform_admin)

    with_mail_admin_host("mailadmin.example.test") do
      host! "mailadmin.example.test"

      get "/users/sign_in"
      assert_response :success
      # The login screen there carries none of the portal's branding.
      assert_match "メールアドレス管理", response.body
      assert_no_match(/FuzokuZero/, response.body)

      post user_session_path, params: { user: { email: admin.email, password: "password1234" } }
      assert_redirected_to "/mailadmin"
    end
  end

  test "without the environment variable everything behaves as before" do
    host! "www.example.com"

    get "/mailadmin"
    assert_response :redirect

    get "/"
    assert_response :success
  end
end
