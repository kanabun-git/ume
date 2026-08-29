require "test_helper"

module Admin
  class ShopsControllerTest < ActionDispatch::IntegrationTest
    # Regression test: Admin::ShopsController#set_shop used to call a bare
    # `authorize @shop` for every action including approve/suspend, but
    # ShopPolicy has no approve?/suspend? methods for Pundit to infer from
    # the action name — every suspend/approve click raised a NoMethodError.
    test "platform admin can suspend an approved shop" do
      admin = create_user(role: :platform_admin)
      shop = create_shop(status: :approved)
      sign_in admin

      patch suspend_admin_shop_path(shop)

      assert_redirected_to admin_shops_path
      assert shop.reload.suspended?
    end

    test "platform admin can approve a pending shop" do
      admin = create_user(role: :platform_admin)
      shop = create_shop(status: :pending)
      sign_in admin

      patch approve_admin_shop_path(shop)

      assert_redirected_to admin_shops_path
      assert shop.reload.approved?
    end

    test "a shop admin cannot suspend a shop" do
      shop = create_shop(status: :approved)
      shop_admin = create_user(role: :shop_admin, shop: shop)
      sign_in shop_admin

      patch suspend_admin_shop_path(shop)

      assert_not shop.reload.suspended?
    end

    test "platform admin can restore a suspended shop back to approved" do
      admin = create_user(role: :platform_admin)
      shop = create_shop(status: :suspended)
      sign_in admin

      patch approve_admin_shop_path(shop)

      assert_redirected_to admin_shops_path
      assert shop.reload.approved?
    end

    # Regression test: the shop list only ever rendered the "承認" button
    # inside `if shop.pending?`, so once a shop moved from pending straight
    # to suspended, no button on the page could call approve_admin_shop_path
    # again — suspending a shop was a one-way trip with no way back short of
    # editing the database directly.
    test "index shows a restore button for a suspended shop" do
      admin = create_user(role: :platform_admin)
      shop = create_shop(status: :suspended)
      sign_in admin

      get admin_shops_path

      assert_select "form[action=?]", approve_admin_shop_path(shop) do
        assert_select "button", text: "復帰"
      end
    end

    test "platform admin can confirm a shop's design change notice" do
      admin = create_user(role: :platform_admin)
      shop = create_shop(design_updated_at: Time.current)
      sign_in admin

      patch confirm_design_admin_shop_path(shop)

      assert_redirected_to admin_shops_path
      assert_not shop.reload.design_change_pending?
    end

    test "a shop admin cannot confirm their own design change notice" do
      shop = create_shop(design_updated_at: Time.current)
      shop_admin = create_user(role: :shop_admin, shop: shop)
      sign_in shop_admin

      patch confirm_design_admin_shop_path(shop)

      assert shop.reload.design_change_pending?
    end

    test "show links to a preview of the shop's page, even when unpublished" do
      admin = create_user(role: :platform_admin)
      shop = create_shop(published: false)
      sign_in admin

      get admin_shop_path(shop)

      assert_select "a[href=?][target=_blank]", shop_path(shop), text: "店舗ページのプレビューを見る"
    end

    test "a platform admin can delete one of a shop's uploaded photos" do
      admin = create_user(role: :platform_admin)
      shop = create_shop
      shop.photos.attach(**png_upload(filename: "a.png"))
      shop.photos.attach(**png_upload(filename: "b.png"))
      photo_to_delete = shop.photos.first
      sign_in admin

      delete destroy_photo_admin_shop_path(shop, photo_id: photo_to_delete.id)

      assert_redirected_to edit_admin_shop_path(shop)
      assert_equal 1, shop.reload.photos.count
    end

    test "a shop admin cannot delete a shop's photo from the admin namespace" do
      shop = create_shop
      shop.photos.attach(**png_upload(filename: "a.png"))
      photo = shop.photos.first
      shop_admin = create_user(role: :shop_admin, shop: shop)
      sign_in shop_admin

      delete destroy_photo_admin_shop_path(shop, photo_id: photo.id)

      assert_redirected_to root_path
      assert shop.reload.photos.attached?
    end

    test "index shows a design change notice with a confirm button for a shop that just published" do
      admin = create_user(role: :platform_admin)
      shop = create_shop(design_updated_at: Time.current)
      sign_in admin

      get admin_shops_path

      assert_select "form[action=?]", confirm_design_admin_shop_path(shop) do
        assert_select "button", text: "確認"
      end
    end
  end
end
