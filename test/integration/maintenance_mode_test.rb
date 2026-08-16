require "test_helper"

class MaintenanceModeTest < ActionDispatch::IntegrationTest
  test "public pages show the default message when maintenance mode is on with no customization" do
    with_maintenance_mode_on do
      get root_path

      assert_response :service_unavailable
      assert_select "h1", "ただいまメンテナンス中です"
      assert_select "p", text: /ただいまサイトのメンテナンスを行っております/
    end
  end

  test "a custom message replaces the default text" do
    SiteSetting.instance.update!(maintenance_message: "臨時メンテナンス中です")

    with_maintenance_mode_on do
      get root_path

      assert_select "p", text: /臨時メンテナンス中です/
    end
  end

  test "a maintenance image takes priority over the message" do
    setting = SiteSetting.instance
    setting.update!(maintenance_message: "このメッセージは表示されないはず")
    setting.maintenance_image.attach(io: StringIO.new(png_bytes), filename: "maintenance.png", content_type: "image/png")

    with_maintenance_mode_on do
      get root_path

      assert_select ".maintenance-image img"
      assert_select "p", text: /このメッセージは表示されないはず/, count: 0
    end
  end

  test "with no banner image, a text link to the shop inquiry page is shown" do
    with_maintenance_mode_on do
      get root_path

      assert_select "a.maintenance-banner-link[href=?]", new_shop_inquiry_path
    end
  end

  test "with a banner image, it links to the shop inquiry page instead of the text link" do
    SiteSetting.instance.maintenance_banner_image.attach(io: StringIO.new(png_bytes), filename: "banner.png", content_type: "image/png")

    with_maintenance_mode_on do
      get root_path

      assert_select ".maintenance-banner a[href=?] img", new_shop_inquiry_path
      assert_select "a.maintenance-banner-link", count: 0
    end
  end

  test "the shop inquiry pages stay reachable during maintenance" do
    with_maintenance_mode_on do
      get new_shop_inquiry_path
      assert_response :success
    end
  end

  test "the admin, shop_admin, and cast portal areas stay reachable during maintenance" do
    with_maintenance_mode_on do
      get new_user_session_path
      assert_response :success
    end
  end

  private

  def with_maintenance_mode_on
    SiteSetting.instance.update!(maintenance_mode: true)
    yield
  ensure
    SiteSetting.instance.update!(maintenance_mode: false)
  end

  def png_bytes
    Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")
  end
end
