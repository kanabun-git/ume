require "test_helper"

module ShopAdmin
  class ReviewsControllerTest < ActionDispatch::IntegrationTest
    test "a shop admin can reply to a review left for their own shop" do
      shop = create_shop
      review = shop.reviews.create!(reviewer_name: "利用者A", rating: 5, body: "良かったです")
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      patch reply_shop_admin_review_path(review), params: { shop_reply: "ありがとうございました。" }

      assert_redirected_to shop_admin_reviews_path
      assert_equal "ありがとうございました。", review.reload.shop_reply
      assert review.reload.shop_replied_at.present?
    end

    test "a shop admin cannot reply to another shop's review" do
      other_shop = create_shop
      review = other_shop.reviews.create!(reviewer_name: "利用者A", rating: 5, body: "良かったです")
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      patch reply_shop_admin_review_path(review), params: { shop_reply: "返信" }

      assert_response :not_found
    end
  end
end
