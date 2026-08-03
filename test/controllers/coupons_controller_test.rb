require "test_helper"

class CouponsControllerTest < ActionDispatch::IntegrationTest
  test "lists only shops with an active coupon" do
    with_coupon = create_shop(name: "クーポン店舗", coupon_available: true, coupon_description: "初回割引あり")
    without_coupon = create_shop(name: "クーポンなし店舗", coupon_available: false)

    get coupons_path

    assert_response :success
    assert_match with_coupon.name, response.body
    assert_no_match without_coupon.name, response.body
  end

  test "excludes shops that are not approved even if they have a coupon" do
    suspended_shop = create_shop(name: "停止中クーポン店舗", coupon_available: true, status: :suspended)

    get coupons_path

    assert_response :success
    assert_no_match suspended_shop.name, response.body
  end

  test "filters by genre_id" do
    matching_genre = create_genre
    other_genre = create_genre
    matching_shop = create_shop(name: "対象ジャンル店舗", coupon_available: true, genre: matching_genre)
    other_shop = create_shop(name: "対象外ジャンル店舗", coupon_available: true, genre: other_genre)

    get coupons_path, params: { genre_id: matching_genre.id }

    assert_response :success
    assert_match matching_shop.name, response.body
    assert_no_match other_shop.name, response.body
  end
end
