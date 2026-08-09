require "test_helper"

# Verifies that pages rendered on the dedicated cast portal host (see
# ApplicationController#discreet_cast_portal_host?) never leak the site's
# real branding -- neither the cast dashboard itself, nor the shared Devise
# sign-in screen a signed-out cast member is redirected to. Reloads routes
# around the CAST_PORTAL_HOST change for the same reason
# cast_portal_host_constraint_test.rb does (routes are drawn lazily in this
# environment, so an ENV mutation can otherwise apply retroactively).
class DiscreetCastPortalLayoutTest < ActionDispatch::IntegrationTest
  def with_cast_portal_host(host)
    original = ENV["CAST_PORTAL_HOST"]
    ENV["CAST_PORTAL_HOST"] = host
    Rails.application.reload_routes!
    yield
  ensure
    ENV["CAST_PORTAL_HOST"] = original
    Rails.application.reload_routes!
  end

  test "the sign-in screen uses the neutral shell and no site branding when reached on the cast portal host" do
    with_cast_portal_host("staff.example.test") do
      host! "staff.example.test"

      get new_user_session_path

      assert_response :success
      assert_match "cast-portal-public", response.body
      assert_no_match "FuzokuZero", response.body
    end
  end

  test "the sign-in screen keeps the normal site branding on the main host" do
    host! "www.example.com"

    get new_user_session_path

    assert_response :success
    assert_no_match "cast-portal-public", response.body
  end

  test "the cast dashboard uses the neutral shell and title on the configured cast portal host" do
    cast = create_cast
    user = create_user(role: :cast, shop: cast.shop)
    cast.update!(user: user)

    with_cast_portal_host("staff.example.test") do
      host! "staff.example.test"
      sign_in user

      get cast_root_path

      assert_response :success
      assert_match "cast-portal-shell", response.body
      assert_match "スタッフポータル", response.body
      assert_no_match "FuzokuZero", response.body
    end
  end
end
