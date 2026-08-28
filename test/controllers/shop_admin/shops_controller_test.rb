require "test_helper"

module ShopAdmin
  class ShopsControllerTest < ActionDispatch::IntegrationTest
    test "a shop admin can set their own PR badge display period" do
      shop = create_shop
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      patch shop_admin_shop_path, params: { shop: { pr_badge_until: 1.day.from_now } }

      assert_redirected_to shop_admin_root_path
      assert shop.reload.pr_badge_active?
    end

    test "a shop admin cannot change fields reserved for the platform admin" do
      shop = create_shop
      other_plan = create_plan
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      patch shop_admin_shop_path, params: { shop: { name: "改名後", plan_id: other_plan.id } }

      assert_not_equal "改名後", shop.reload.name
      assert_not_equal other_plan, shop.plan
    end

    test "a shop admin can set the shop detail page's background/text/accent colors and a background image" do
      shop = create_shop
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      patch shop_admin_shop_path, params: {
        shop: {
          page_background_color: "#112233", page_text_color: "#ffffff", page_accent_color: "#00aa88",
          page_background_image: upload_png
        }
      }

      shop.reload
      assert_equal "#112233", shop.page_background_color
      assert_equal "#ffffff", shop.page_text_color
      assert_equal "#00aa88", shop.page_accent_color
      assert shop.page_background_image.attached?
    end

    test "a shop admin can remove the shop's background image" do
      shop = create_shop
      shop.page_background_image.attach(**png_upload)
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      patch shop_admin_shop_path, params: { shop: { remove_page_background_image: "1" } }

      assert_not shop.reload.page_background_image.attached?
    end

    test "leaving the background image field blank keeps the existing image" do
      shop = create_shop
      shop.page_background_image.attach(**png_upload)
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      patch shop_admin_shop_path, params: { shop: { catch_copy: "更新" } }

      assert shop.reload.page_background_image.attached?
    end

    test "a shop admin can publish their own shop, which stamps a design change notice" do
      shop = create_shop(published: false)
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      patch publish_shop_admin_shop_path

      assert_redirected_to shop_admin_root_path
      shop.reload
      assert shop.published?
      assert shop.design_change_pending?
    end

    test "the edit screen shows a design preview link" do
      shop = create_shop
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      get edit_shop_admin_shop_path

      assert_select "a[href=?]", shop_path(shop), text: "デザインのプレビューを見る"
    end

    test "a shop admin can unpublish their own shop back into draft" do
      shop = create_shop(published: true)
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      patch unpublish_shop_admin_shop_path

      assert_redirected_to shop_admin_root_path
      assert_not shop.reload.published?
    end

    private

    def upload_png
      bytes = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")
      Rack::Test::UploadedFile.new(StringIO.new(bytes), "image/png", original_filename: "bg.png")
    end
  end
end
