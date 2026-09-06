require "test_helper"

# 古着ブランド判定ツールは、本番では www.kanabun.tech だけで開ける
# (VINTAGE_HOST)。そのホストはメールアドレス管理画面のホスト
# (MAIL_ADMIN_HOST)でもあり、MailAdminHostMiddlewareが /mailadmin 以外を
# 全て404にするので、2つの仕組みが噛み合って初めてツールが開く。ここでは
# その組み合わせを通しで確かめる。
#
# ENVを触るのでルートを再読込し、ensureで必ず戻す
# (mail_admin_host_test.rb / cast_portal_host_constraint_test.rb と同じ作法)。
class VintageHostConstraintTest < ActionDispatch::IntegrationTest
  def with_hosts(vintage: nil, mail_admin: nil)
    original_vintage = ENV["VINTAGE_HOST"]
    original_mail_admin = ENV["MAIL_ADMIN_HOST"]
    ENV["VINTAGE_HOST"] = vintage
    ENV["MAIL_ADMIN_HOST"] = mail_admin
    Rails.application.reload_routes!
    yield
  ensure
    ENV["VINTAGE_HOST"] = original_vintage
    ENV["MAIL_ADMIN_HOST"] = original_mail_admin
    Rails.application.reload_routes!
  end

  test "the tool only resolves on the configured host" do
    with_hosts(vintage: "tool.example.test") do
      host! "www.example.com"
      get "/vintage"
      assert_response :not_found

      host! "tool.example.test"
      get "/vintage"
      assert_response :success
      assert_select "h1", "古着ブランド判定ツール"
    end
  end

  test "the tool and the mail admin screen share one host without shutting each other out" do
    with_hosts(vintage: "shared.example.test", mail_admin: "shared.example.test") do
      host! "shared.example.test"

      get "/vintage"
      assert_response :success

      get "/vintage/guide"
      assert_response :success

      get "/mailadmin", headers: mail_admin_auth_headers
      assert_response :success

      # 同居させても、そのホストで他のものが開くようになるわけではない。
      ["/", "/shops", "/admin", "/users/sign_in"].each do |path|
        get path
        assert_response :not_found, "#{path} must not be reachable on the shared host"
      end
    end
  end

  test "the mail admin host keeps shutting the tool out when it is published elsewhere" do
    with_hosts(vintage: "tool.example.test", mail_admin: "mailadmin.example.test") do
      host! "mailadmin.example.test"

      get "/vintage"
      assert_response :not_found
    end
  end

  test "without the environment variable the tool is reachable on any host" do
    host! "www.example.com"

    get "/vintage"
    assert_response :success
  end
end
