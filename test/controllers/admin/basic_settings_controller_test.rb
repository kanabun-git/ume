require "test_helper"

module Admin
  class BasicSettingsControllerTest < ActionDispatch::IntegrationTest
    test "a platform admin can view and upload a basic image" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      get edit_admin_basic_setting_path
      assert_response :success

      file = Rack::Test::UploadedFile.new(StringIO.new(png_bytes), "image/png", original_filename: "card.png")
      patch admin_basic_setting_path, params: { site_setting: { membership_card_image: file } }

      assert_redirected_to edit_admin_basic_setting_path
      assert SiteSetting.instance.membership_card_image.attached?
    end

    test "leaving an image field blank does not remove an already-uploaded image" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      SiteSetting.instance.membership_card_image.attach(io: StringIO.new(png_bytes), filename: "card.png", content_type: "image/png")

      patch admin_basic_setting_path, params: { site_setting: { membership_card_image: "" } }

      assert SiteSetting.instance.reload.membership_card_image.attached?
    end

    test "a platform admin can upload the present ticket default banner image" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      file = Rack::Test::UploadedFile.new(StringIO.new(png_bytes), "image/png", original_filename: "banner.png")
      patch admin_basic_setting_path, params: { site_setting: { present_ticket_default_banner_image: file } }

      assert SiteSetting.instance.present_ticket_default_banner_image.attached?
    end

    test "a shop admin cannot access basic site settings" do
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get edit_admin_basic_setting_path

      assert_redirected_to root_path
    end

    private

    def png_bytes
      Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")
    end
  end
end
