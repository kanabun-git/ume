require "test_helper"

class CouponsControllerTest < ActionDispatch::IntegrationTest
  test "lists active coupons from visible shops" do
    shop = create_shop(name: "クーポン店舗")
    coupon = shop.coupons.create!(title: "テストクーポン", course_name: "60分コース", regular_price: 20000, discounted_price: 14000, valid_from: 1.day.ago.to_date)

    get coupons_path

    assert_response :success
    assert_match coupon.title, response.body
    assert_match shop.name, response.body
  end

  test "excludes a coupon whose shop is suspended" do
    shop = create_shop(status: :suspended)
    coupon = shop.coupons.create!(title: "停止店クーポン", course_name: "60分コース", regular_price: 20000, discounted_price: 14000, valid_from: 1.day.ago.to_date)

    get coupons_path

    assert_response :success
    assert_no_match coupon.title, response.body
  end

  test "excludes a coupon that hasn't started yet" do
    shop = create_shop
    coupon = shop.coupons.create!(title: "未来クーポン", course_name: "60分コース", regular_price: 20000, discounted_price: 14000, valid_from: 1.day.from_now.to_date)

    get coupons_path

    assert_no_match coupon.title, response.body
  end

  test "filtering by a prefecture-level area also matches shops under its child areas" do
    tokyo = create_area
    shinjuku = create_area(parent: tokyo)
    other_pref = create_area
    shop_in_child = create_shop(area: shinjuku, name: "新宿店舗")
    shop_elsewhere = create_shop(area: other_pref, name: "対象外店舗")
    shop_in_child.coupons.create!(title: "新宿クーポン", course_name: "60分", regular_price: 20000, discounted_price: 14000, valid_from: 1.day.ago.to_date)
    shop_elsewhere.coupons.create!(title: "対象外クーポン", course_name: "60分", regular_price: 20000, discounted_price: 14000, valid_from: 1.day.ago.to_date)

    get coupons_path(area_id: tokyo.id)

    assert_match shop_in_child.name, response.body
    assert_no_match shop_elsewhere.name, response.body
  end

  test "filters by genre_id" do
    matching_genre = create_genre
    other_genre = create_genre
    matching_shop = create_shop(genre: matching_genre, name: "対象ジャンル店舗")
    other_shop = create_shop(genre: other_genre, name: "対象外ジャンル店舗")
    matching_shop.coupons.create!(title: "対象クーポン", course_name: "60分", regular_price: 20000, discounted_price: 14000, valid_from: 1.day.ago.to_date)
    other_shop.coupons.create!(title: "対象外クーポン", course_name: "60分", regular_price: 20000, discounted_price: 14000, valid_from: 1.day.ago.to_date)

    get coupons_path(genre_id: matching_genre.id)

    assert_match matching_shop.name, response.body
    assert_no_match other_shop.name, response.body
  end

  test "net_reservation_only filters to net-reservation coupons only" do
    shop = create_shop
    net_coupon = shop.coupons.create!(title: "ネット予約クーポン", course_name: "60分", regular_price: 20000, discounted_price: 14000, valid_from: 1.day.ago.to_date, net_reservation_only: true)
    other_coupon = shop.coupons.create!(title: "通常クーポン", course_name: "90分", regular_price: 20000, discounted_price: 14000, valid_from: 1.day.ago.to_date, net_reservation_only: false)

    get coupons_path(net_reservation_only: "1")

    assert_match net_coupon.title, response.body
    assert_no_match other_coupon.title, response.body
  end

  test "sort=price orders coupons by discounted price ascending" do
    shop = create_shop
    expensive = shop.coupons.create!(title: "高いクーポン", course_name: "A", regular_price: 30000, discounted_price: 20000, valid_from: 1.day.ago.to_date)
    cheap = shop.coupons.create!(title: "安いクーポン", course_name: "B", regular_price: 20000, discounted_price: 8000, valid_from: 1.day.ago.to_date)

    get coupons_path(sort: "price")

    assert_operator response.body.index(cheap.title), :<, response.body.index(expensive.title)
  end
end
