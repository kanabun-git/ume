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

  test "an unpublished (draft) shop's detail page is not publicly reachable" do
    shop = create_shop(published: false)

    get shop_path(shop)

    assert_response :not_found
  end

  test "the shop's own admin can preview an unpublished shop's detail page" do
    shop = create_shop(published: false, name: "下書き中の店舗")
    user = create_user(role: :shop_admin, shop: shop)
    sign_in user

    get shop_path(shop)

    assert_response :success
    assert_includes response.body, shop.name
  end

  test "a platform admin can preview an unpublished shop's detail page" do
    shop = create_shop(published: false, name: "下書き中の店舗")
    admin = create_user(role: :platform_admin)
    sign_in admin

    get shop_path(shop)

    assert_response :success
  end

  test "another shop's admin cannot preview an unpublished shop's detail page" do
    shop = create_shop(published: false)
    other_shop = create_shop
    user = create_user(role: :shop_admin, shop: other_shop)
    sign_in user

    get shop_path(shop)

    assert_response :not_found
  end

  test "previewing an unpublished shop does not record a public view" do
    shop = create_shop(published: false)
    user = create_user(role: :shop_admin, shop: shop)
    sign_in user

    get shop_path(shop)

    assert_nil ShopDailyView.find_by(shop: shop, view_date: Date.current)
    assert_equal 0, shop.reload.view_count
  end

  test "viewing a shop records a daily view" do
    shop = create_shop

    get shop_path(shop)
    get shop_path(shop)

    daily_view = ShopDailyView.find_by(shop: shop, view_date: Date.current)
    assert_equal 2, daily_view.views_count
  end

  test "applies the shop's custom background/text/accent theme to the detail page" do
    shop = create_shop(page_background_color: "#112233", page_text_color: "#ffffff", page_accent_color: "#00aa88")

    get shop_path(shop)

    assert_response :success
    assert_match "background-color: #112233;", response.body
    assert_match "color: #ffffff;", response.body
    assert_match "--brand: #00aa88;", response.body
  end

  test "falls back to the default theme when no custom colors are set" do
    shop = create_shop

    get shop_path(shop)

    assert_response :success
    assert_match(/class="shop-theme-page" style="\s*"/, response.body)
  end

  test "the shop_info block shows the shop's address, phone, and hours" do
    shop = create_shop(address: "テスト住所1-2-3", phone: "0312345678", business_hours: "12:00-24:00")
    shop.shop_page_blocks.destroy_all
    shop.shop_page_blocks.create!(block_type: :shop_info, position: 0)

    get shop_path(shop)

    assert_match "テスト住所1-2-3", response.body
    assert_match "0312345678", response.body
    assert_match "12:00-24:00", response.body
  end

  test "the shop_info block can be repositioned and hidden like any other block" do
    shop = create_shop
    shop.shop_page_blocks.destroy_all
    shop.shop_page_blocks.create!(block_type: :shop_info, position: 0, visible: false)

    get shop_path(shop)

    assert_no_match shop.address, response.body
  end

  test "the recruiting block shows recruiting info when the shop is recruiting" do
    shop = create_shop(recruiting_cast: true, recruiting_message: "急募中です")
    shop.shop_page_blocks.destroy_all
    shop.shop_page_blocks.create!(block_type: :recruiting, position: 0)

    get shop_path(shop)

    assert_match "コンパニオン募集", response.body
    assert_match "急募中です", response.body
  end

  test "the recruiting block does not render when the shop is not recruiting" do
    shop = create_shop(recruiting_cast: false, recruiting_staff: false)
    shop.shop_page_blocks.destroy_all
    shop.shop_page_blocks.create!(block_type: :recruiting, position: 0)

    get shop_path(shop)

    assert_no_match "求人情報", response.body
  end

  test "the recruiting block can still be hidden manually even while the shop is recruiting" do
    shop = create_shop(recruiting_cast: true, recruiting_message: "急募中です")
    shop.shop_page_blocks.destroy_all
    shop.shop_page_blocks.create!(block_type: :recruiting, position: 0, visible: false)

    get shop_path(shop)

    assert_no_match "急募中です", response.body
  end

  test "a page block shows its title band and frame by default" do
    shop = create_shop
    shop.shop_page_blocks.destroy_all
    block = shop.shop_page_blocks.create!(block_type: :free_text, position: 0, settings: { "body" => "サンプル本文" })

    get shop_path(shop)

    assert_select "div.obi-header", text: block.label
    assert_select "div.obi-body", text: /サンプル本文/
    assert_no_match "no-header", response.body
  end

  test "hide_header removes the title band and frame but keeps the block's content" do
    shop = create_shop
    shop.shop_page_blocks.destroy_all
    shop.shop_page_blocks.create!(block_type: :free_text, position: 0, hide_header: true, settings: { "body" => "サンプル本文" })

    get shop_path(shop)

    assert_select "div.obi-header", text: "フリーテキスト", count: 0
    assert_select "div.obi-block.no-header" do
      assert_select "div.obi-body.no-header", text: /サンプル本文/
    end
  end

  test "a block with visible off does not render at all, content included" do
    shop = create_shop
    shop.shop_page_blocks.destroy_all
    shop.shop_page_blocks.create!(block_type: :free_text, position: 0, visible: false, settings: { "body" => "見えないはずの本文" })

    get shop_path(shop)

    assert_no_match "見えないはずの本文", response.body
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

  test "a long review body is folded into a collapsible details element" do
    shop = create_shop
    long_body = "とても良かったです。" * 20
    Review.create!(shop: shop, reviewer_name: "テスト太郎", body: long_body, rating: 5, status: :approved)

    get shop_path(shop)

    assert_select "details.review-body p", text: long_body
  end

  test "a short review body is shown plainly without folding" do
    shop = create_shop
    Review.create!(shop: shop, reviewer_name: "テスト太郎", body: "良かったです。", rating: 5, status: :approved)

    get shop_path(shop)

    assert_select "details.review-body", count: 0
    assert_match "良かったです。", response.body
  end

  test "the cast roster, present tickets, coupons, and reviews sections all share the block title-band style" do
    shop = create_shop
    create_cast(shop: shop)
    PresentTicket.create!(shop: shop, name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)
    Coupon.create!(shop: shop, title: "テストクーポン", course_name: "60分コース", regular_price: 12_000, discounted_price: 10_000, valid_from: Date.current)
    Review.create!(shop: shop, reviewer_name: "テスト太郎", body: "良かったです。", rating: 5, status: :approved)

    get shop_path(shop)

    assert_select "div.obi-block > div.obi-header", text: "在籍キャスト"
    assert_select "div.obi-block > div.obi-header", text: "プレゼント企画"
    assert_select "div.obi-block > div.obi-header", text: "クーポン"
    assert_select "div.obi-block > div.obi-header", text: "口コミ"
  end
end
