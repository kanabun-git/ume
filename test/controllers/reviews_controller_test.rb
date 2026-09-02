require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  test "the index page lists a shop's approved reviews" do
    shop = create_shop
    shop.reviews.create!(reviewer_name: "テスト太郎", body: "良かったです。", rating: 5, status: :approved)
    shop.reviews.create!(reviewer_name: "テスト花子", body: "微妙でした。", rating: 2, status: :pending)

    get shop_reviews_path(shop)

    assert_response :success
    assert_match "良かったです。", response.body
    assert_no_match "微妙でした。", response.body
  end

  test "the reviews page of an unpublished shop is not publicly reachable" do
    shop = create_shop(published: false)

    get shop_reviews_path(shop)

    assert_response :not_found
  end

  test "the shop's own admin can preview the reviews page of an unpublished shop" do
    shop = create_shop(published: false)
    shop.reviews.create!(reviewer_name: "テスト太郎", body: "良かったです。", rating: 5, status: :approved)
    user = create_user(role: :shop_admin, shop: shop)
    sign_in user

    get shop_reviews_path(shop)

    assert_response :success
    assert_match "良かったです。", response.body
  end

  test "a platform admin can preview the reviews page of an unpublished shop" do
    shop = create_shop(published: false)
    admin = create_user(role: :platform_admin)
    sign_in admin

    get shop_reviews_path(shop)

    assert_response :success
  end

  test "another shop's admin cannot preview an unpublished shop's reviews page" do
    shop = create_shop(published: false)
    other_shop = create_shop
    user = create_user(role: :shop_admin, shop: other_shop)
    sign_in user

    get shop_reviews_path(shop)

    assert_response :not_found
  end

  test "a long review body is folded into a collapsible details element on the index page" do
    shop = create_shop
    long_body = "とても良かったです。" * 20
    Review.create!(shop: shop, reviewer_name: "テスト太郎", body: long_body, rating: 5, status: :approved)

    get shop_reviews_path(shop)

    assert_select "details.review-body p", text: long_body
  end

  test "a short review body is shown plainly without folding on the index page" do
    shop = create_shop
    Review.create!(shop: shop, reviewer_name: "テスト太郎", body: "良かったです。", rating: 5, status: :approved)

    get shop_reviews_path(shop)

    assert_select "details.review-body", count: 0
    assert_match "良かったです。", response.body
  end

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

  test "a review submitted while signed in as a member is linked to that member" do
    shop = create_shop
    member = create_member
    sign_in member

    post shop_reviews_path(shop), params: { review: { reviewer_name: "利用者A", rating: 5, body: "良かったです" } }

    assert_equal member, shop.reviews.last.member
  end

  test "a review's member cannot be spoofed via the submitted params" do
    shop = create_shop
    other_member = create_member

    post shop_reviews_path(shop), params: { review: { reviewer_name: "利用者A", rating: 5, body: "良かったです", member_id: other_member.id } }

    assert_nil shop.reviews.last.member
  end

  test "a visitor can mark a review as helpful" do
    shop = create_shop
    review = shop.reviews.create!(reviewer_name: "A", rating: 5, body: "良い店でした", status: :approved)

    post helpful_shop_review_path(shop, review)

    assert_redirected_to shop_path(shop)
    assert_equal 1, review.reload.review_helpful_votes.count
  end

  test "voting helpful on the same review twice from the same client only counts once" do
    shop = create_shop
    review = shop.reviews.create!(reviewer_name: "A", rating: 5, body: "良い店でした", status: :approved)

    post helpful_shop_review_path(shop, review)
    post helpful_shop_review_path(shop, review)

    assert_equal 1, review.reload.review_helpful_votes.count
  end

  test "a second rapid submission from the same client is rejected" do
    shop = create_shop
    post shop_reviews_path(shop), params: { review: { reviewer_name: "利用者A", rating: 5, body: "1件目" } }

    post shop_reviews_path(shop), params: { review: { reviewer_name: "利用者A", rating: 4, body: "2件目" } }

    assert_response :unprocessable_entity
    assert_equal 1, shop.reviews.count
  end
end
