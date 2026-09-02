require "test_helper"

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    test "platform admin can issue an account setup link for a shop admin" do
      admin = create_user(role: :platform_admin)
      shop = create_shop
      target = create_user(role: :shop_admin, shop: shop, password: "password1234")
      sign_in admin

      post issue_account_setup_link_admin_user_path(target)

      assert_response :success
      assert_includes @response.body, "reset_password_token="
      assert target.reload.reset_password_token.present?
    end

    test "platform admin can send an account setup email to a shop admin" do
      admin = create_user(role: :platform_admin)
      shop = create_shop
      target = create_user(role: :shop_admin, shop: shop, password: "password1234")
      sign_in admin

      assert_emails 1 do
        post send_account_setup_email_admin_user_path(target)
      end

      assert_redirected_to admin_user_path(target)
      assert target.reload.reset_password_token.present?
      assert_equal [target.email], ActionMailer::Base.deliveries.last.to
    end

    test "a shop admin cannot send an account setup email (admin namespace is platform-admin only)" do
      shop = create_shop
      shop_admin = create_user(role: :shop_admin, shop: shop)
      target = create_user(role: :shop_admin, shop: create_shop)
      sign_in shop_admin

      assert_no_emails do
        post send_account_setup_email_admin_user_path(target)
      end

      assert_redirected_to root_path
    end

    test "a shop admin cannot issue an account setup link (admin namespace is platform-admin only)" do
      shop = create_shop
      shop_admin = create_user(role: :shop_admin, shop: shop)
      target = create_user(role: :shop_admin, shop: create_shop)
      sign_in shop_admin

      post issue_account_setup_link_admin_user_path(target)

      assert_redirected_to root_path
      assert_nil target.reload.reset_password_token
    end

    test "new prefills shop_id and role from query params without persisting anything" do
      admin = create_user(role: :platform_admin)
      shop = create_shop
      sign_in admin

      get new_admin_user_path(shop_id: shop.id, role: "shop_admin")

      assert_response :success
      assert_select "select#user_shop_id option[selected][value=?]", shop.id.to_s
    end
  end
end
