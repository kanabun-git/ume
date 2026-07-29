require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  test "a normal review submission is saved" do
    shop = create_shop

    post shop_reviews_path(shop), params: { review: { reviewer_name: "利用者A", rating: 5, body: "良かったです" } }

    assert_redirected_to shop_path(shop)
    assert_equal 1, shop.reviews.count
  end

  test "filling the honeypot field silently discards the submission" do
    shop = create_shop

    post shop_reviews_path(shop), params: { review: { reviewer_name: "bot", rating: 5, body: "spam", website: "http://spam.example" } }

    assert_redirected_to shop_path(shop) # looks identical to a real success, so the bot isn't tipped off
    assert_equal 0, shop.reviews.count
  end

  test "a second rapid submission from the same client is rejected" do
    shop = create_shop
    post shop_reviews_path(shop), params: { review: { reviewer_name: "利用者A", rating: 5, body: "1件目" } }

    post shop_reviews_path(shop), params: { review: { reviewer_name: "利用者A", rating: 4, body: "2件目" } }

    assert_response :unprocessable_entity
    assert_equal 1, shop.reviews.count
  end
end
