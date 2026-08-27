require "test_helper"

module Admin
  class ShopInquiryReplyTemplatesControllerTest < ActionDispatch::IntegrationTest
    test "a platform admin can view and update the reply template" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      get edit_admin_shop_inquiry_reply_template_path
      assert_response :success

      patch admin_shop_inquiry_reply_template_path, params: {
        shop_inquiry_reply_template: { body: "新しい定型文です。" }
      }

      assert_redirected_to edit_admin_shop_inquiry_reply_template_path
      assert_equal "新しい定型文です。", ShopInquiryReplyTemplate.instance.reload.body
    end

    test "saving a blank body is rejected" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      patch admin_shop_inquiry_reply_template_path, params: { shop_inquiry_reply_template: { body: "" } }

      assert_response :unprocessable_entity
    end

    test "a shop admin cannot access the reply template screen" do
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get edit_admin_shop_inquiry_reply_template_path

      assert_redirected_to root_path
    end
  end
end
