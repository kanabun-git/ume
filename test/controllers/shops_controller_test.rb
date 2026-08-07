require "test_helper"

class ShopsControllerTest < ActionDispatch::IntegrationTest
  test "keyword filters shops by name" do
    matching = create_shop(name: "新宿サンプル店")
    create_shop(name: "池袋サンプル店")

    get shops_path(keyword: "新宿")

    assert_response :success
    assert_includes @response.body, matching.name
    assert_not_includes @response.body, "池袋サンプル店"
  end

  test "max_price filters out shops priced above the ceiling" do
    cheap = create_shop(min_price: 10_000)
    create_shop(min_price: 30_000)

    get shops_path(max_price: 15_000)

    assert_includes @response.body, cheap.name
  end

  test "cup filters to shops with at least one active cast of that cup size" do
    shop = create_shop
    create_cast(shop: shop, cup: "F")
    other_shop = create_shop

    get shops_path(cup: "F")

    assert_includes @response.body, shop.name
    assert_not_includes @response.body, other_shop.name
  end

  test "a suspended shop's detail page is not publicly reachable" do
    shop = create_shop(status: :suspended)

    get shop_path(shop)

    assert_response :not_found
  end

  test "viewing a shop records a daily view" do
    shop = create_shop

    get shop_path(shop)
    get shop_path(shop)

    daily_view = ShopDailyView.find_by(shop: shop, view_date: Date.current)
    assert_equal 2, daily_view.views_count
  end

  test "shows the member's rank badge for a shop they hold a membership at" do
    shop = create_shop
    member = create_member
    membership = ShopMembership.create!(shop: shop, member: member)
    ShopMemberRank.create!(shop: shop, name: "レギュラー会員", min_visit_count: 1)
    membership.record_visit!(visited_on: Date.current)
    sign_in member

    get shop_path(shop)

    assert_match "この店舗の会員ランク", response.body
    assert_match "レギュラー会員", response.body
  end

  test "does not show a rank badge for a member with no membership at the shop" do
    shop = create_shop
    member = create_member
    sign_in member

    get shop_path(shop)

    assert_no_match "この店舗の会員ランク", response.body
  end

  test "does not show a rank badge for a signed-out visitor" do
    shop = create_shop

    get shop_path(shop)

    assert_no_match "この店舗の会員ランク", response.body
  end

  test "an unverified member sees a disabled present ticket button with an SMS verification prompt" do
    shop = create_shop
    PresentTicket.create!(shop: shop, name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)
    member = create_member
    sign_in member

    get shop_path(shop)

    assert_match "btn disabled", response.body
    assert_match "※SMS認証後有効化されます。", response.body
    assert_match "SMS認証はこちら", response.body
  end

  test "a phone-verified member sees an enabled present ticket apply button" do
    shop = create_shop
    PresentTicket.create!(shop: shop, name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)
    member = create_member(phone_verified_at: Time.current)
    sign_in member

    get shop_path(shop)

    assert_no_match "btn disabled", response.body
    assert_match "応募する", response.body
  end
end
