require "test_helper"

module Admin
  class ReviewsControllerTest < ActionDispatch::IntegrationTest
    test "a platform admin can reply to any shop's review" do
      shop = create_shop
      review = shop.reviews.create!(reviewer_name: "利用者A", rating: 5, body: "良かったです")
      admin = create_user(role: :platform_admin)
      sign_in admin

      patch reply_admin_review_path(review), params: { shop_reply: "運営者より返信いたします。" }

      assert_redirected_to admin_reviews_path
      assert_equal "運営者より返信いたします。", review.reload.shop_reply
      assert review.reload.shop_replied_at.present?
    end
  end
end
