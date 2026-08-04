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
  end
end
