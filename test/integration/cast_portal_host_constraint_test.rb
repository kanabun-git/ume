require "test_helper"

# Verifies the CAST_PORTAL_HOST routing constraint from config/routes.rb:
# once configured, /cast/* only resolves on that dedicated host, and stays
# reachable on any host otherwise (so local dev needs no setup). Reloads
# routes to pick up the ENV change, restoring both in an `ensure` so this
# doesn't leak into other tests running in the same parallel worker.
class CastPortalHostConstraintTest < ActionDispatch::IntegrationTest
  test "the cast portal only resolves on the configured CAST_PORTAL_HOST" do
    original = ENV["CAST_PORTAL_HOST"]
    ENV["CAST_PORTAL_HOST"] = "staff.example.test"
    Rails.application.reload_routes!

    host! "www.example.com"
    get "/cast"
    assert_response :not_found

    host! "staff.example.test"
    get "/cast"
    assert_response :redirect
  ensure
    ENV["CAST_PORTAL_HOST"] = original
    Rails.application.reload_routes!
  end

  test "the cast portal resolves on any host when CAST_PORTAL_HOST is unset" do
    original = ENV["CAST_PORTAL_HOST"]
    ENV.delete("CAST_PORTAL_HOST")
    Rails.application.reload_routes!

    host! "www.example.com"
    get "/cast"
    assert_response :redirect
  ensure
    ENV["CAST_PORTAL_HOST"] = original
    Rails.application.reload_routes!
  end
end
