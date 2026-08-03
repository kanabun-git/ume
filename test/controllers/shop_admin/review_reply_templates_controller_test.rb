require "test_helper"

module ShopAdmin
  class ReviewReplyTemplatesControllerTest < ActionDispatch::IntegrationTest
    test "a shop admin can create a reply template for their own shop" do
      shop = create_shop
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      post shop_admin_review_reply_templates_path, params: { review_reply_template: { title: "お礼", body: "ご来店ありがとうございました。" } }

      assert_redirected_to shop_admin_review_reply_templates_path
      assert_equal 1, shop.review_reply_templates.count
    end

    test "a shop admin can update and delete their own template" do
      shop = create_shop
      user = create_user(role: :shop_admin, shop: shop)
      template = shop.review_reply_templates.create!(title: "お礼", body: "ありがとうございました。")
      sign_in user

      patch shop_admin_review_reply_template_path(template), params: { review_reply_template: { body: "いつもありがとうございます。" } }
      assert_equal "いつもありがとうございます。", template.reload.body

      delete shop_admin_review_reply_template_path(template)
      assert_not ReviewReplyTemplate.exists?(template.id)
    end

    test "a shop admin cannot manage another shop's template" do
      other_shop = create_shop
      template = other_shop.review_reply_templates.create!(title: "お礼", body: "ありがとうございました。")
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      patch shop_admin_review_reply_template_path(template), params: { review_reply_template: { body: "書き換え" } }

      assert_response :not_found
    end
  end
end
