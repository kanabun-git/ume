require "test_helper"

# Covers MaintenanceModeMiddleware's behavior, including the banner-image
# override added alongside SiteSetting#maintenance_banner_image: when set,
# the maintenance page shows only that image, with none of the usual
# heading/message/card chrome.
class MaintenanceModeTest < ActionDispatch::IntegrationTest
  def with_maintenance_mode(message: nil, banner_image: nil)
    setting = SiteSetting.instance
    setting.update!(maintenance_mode: true, maintenance_message: message)
    setting.maintenance_banner_image.attach(banner_image) if banner_image
    yield
  ensure
    SiteSetting.instance.update!(maintenance_mode: false)
  end

  test "without a banner image, the usual heading and message are shown" do
    with_maintenance_mode(message: "案内メッセージです") do
      get "/"

      assert_response :service_unavailable
      assert_match "<h1>ただいまメンテナンス中です</h1>", response.body
      assert_match "<span>案内メッセージです</span>", response.body
      assert_no_match(/<img[^>]*maintenance-banner/, response.body)
    end
  end

  test "with a banner image, only the image is shown -- no heading, message, or card" do
    with_maintenance_mode(message: "案内メッセージです", banner_image: png_upload) do
      get "/"

      assert_response :service_unavailable
      assert_match(/<img[^>]*maintenance-banner/, response.body)
      assert_no_match "<h1>", response.body
      assert_no_match "<span>案内メッセージです</span>", response.body
      assert_no_match 'class="card"', response.body
    end
  end

  test "back-office areas stay reachable during maintenance mode regardless of the banner" do
    with_maintenance_mode(banner_image: png_upload) do
      get new_user_session_path

      assert_response :success
    end
  end
end
