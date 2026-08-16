require "test_helper"

module Admin
  class SettingsControllerTest < ActionDispatch::IntegrationTest
    test "a platform admin can turn on maintenance mode and set a message" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      get edit_admin_setting_path
      assert_response :success

      patch admin_setting_path, params: { site_setting: { maintenance_mode: "1", maintenance_message: "臨時メンテナンス中です" } }

      assert_redirected_to edit_admin_setting_path
      setting = SiteSetting.instance.reload
      assert setting.maintenance_mode?
      assert_equal "臨時メンテナンス中です", setting.maintenance_message
    end

    test "a platform admin can upload a maintenance image and banner image" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      image = Rack::Test::UploadedFile.new(StringIO.new(png_bytes), "image/png", original_filename: "maintenance.png")
      banner = Rack::Test::UploadedFile.new(StringIO.new(png_bytes), "image/png", original_filename: "banner.png")

      patch admin_setting_path, params: { site_setting: { maintenance_image: image, maintenance_banner_image: banner } }

      setting = SiteSetting.instance.reload
      assert setting.maintenance_image.attached?
      assert setting.maintenance_banner_image.attached?
    end

    test "leaving the image fields blank does not remove already-uploaded images" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      SiteSetting.instance.maintenance_image.attach(io: StringIO.new(png_bytes), filename: "old.png", content_type: "image/png")

      patch admin_setting_path, params: { site_setting: { maintenance_mode: "1", maintenance_image: "" } }

      assert SiteSetting.instance.reload.maintenance_image.attached?
    end

    test "a shop admin cannot access site settings" do
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get edit_admin_setting_path

      assert_redirected_to root_path
    end

    private

    def png_bytes
      Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")
    end
  end
end
