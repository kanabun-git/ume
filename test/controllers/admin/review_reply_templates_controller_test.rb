require "test_helper"

module Admin
  class ReviewReplyTemplatesControllerTest < ActionDispatch::IntegrationTest
    test "a platform admin can manage any shop's reply templates" do
      shop = create_shop
      admin = create_user(role: :platform_admin)
      sign_in admin

      post admin_shop_review_reply_templates_path(shop), params: { review_reply_template: { title: "お礼", body: "ご来店ありがとうございました。" } }

      assert_redirected_to admin_shop_review_reply_templates_path(shop)
      assert_equal 1, shop.review_reply_templates.count

      template = shop.review_reply_templates.last
      patch admin_shop_review_reply_template_path(shop, template), params: { review_reply_template: { body: "更新後の返信文" } }
      assert_equal "更新後の返信文", template.reload.body

      delete admin_shop_review_reply_template_path(shop, template)
      assert_not ReviewReplyTemplate.exists?(template.id)
    end

    test "a shop admin cannot access the admin-namespaced templates screen" do
      shop = create_shop
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      get admin_shop_review_reply_templates_path(shop)

      assert_redirected_to root_path
    end
  end
end
