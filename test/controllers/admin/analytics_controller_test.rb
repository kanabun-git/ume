require "test_helper"

module Admin
  class AnalyticsControllerTest < ActionDispatch::IntegrationTest
    test "shows the site-wide daily total and a shop ranking" do
      admin = create_user(role: :platform_admin)
      popular_shop = create_shop(name: "人気店舗")
      quiet_shop = create_shop(name: "静かな店舗")
      ShopDailyView.create!(shop: popular_shop, view_date: Date.current, views_count: 10)
      ShopDailyView.create!(shop: quiet_shop, view_date: Date.current, views_count: 1)
      sign_in admin

      get admin_analytics_path

      assert_response :success
      assert_includes @response.body, popular_shop.name
      assert_includes @response.body, quiet_shop.name
    end

    test "filtering by shop_id shows only that shop's own trend, not the ranking table" do
      admin = create_user(role: :platform_admin)
      shop = create_shop(name: "対象店舗")
      other_shop = create_shop(name: "対象外店舗")
      ShopDailyView.create!(shop: shop, view_date: Date.current, views_count: 5)
      ShopDailyView.create!(shop: other_shop, view_date: Date.current, views_count: 5)
      sign_in admin

      get admin_analytics_path(shop_id: shop.id)

      assert_response :success
      assert_includes @response.body, "#{shop.name} の閲覧数推移"
      assert_not_includes @response.body, "店舗別閲覧数ランキング"
    end

    test "shows the site-wide cast daily total and a cast ranking" do
      admin = create_user(role: :platform_admin)
      popular_cast = create_cast(name: "人気キャスト")
      quiet_cast = create_cast(name: "静かなキャスト")
      CastDailyView.create!(cast: popular_cast, view_date: Date.current, views_count: 10)
      CastDailyView.create!(cast: quiet_cast, view_date: Date.current, views_count: 1)
      sign_in admin

      get admin_analytics_path(page_type: "cast")

      assert_response :success
      assert_includes @response.body, popular_cast.name
      assert_includes @response.body, quiet_cast.name
    end

    test "filtering by cast_id shows only that cast's own trend, not the ranking table" do
      admin = create_user(role: :platform_admin)
      cast = create_cast(name: "対象キャスト")
      other_cast = create_cast(name: "対象外キャスト")
      CastDailyView.create!(cast: cast, view_date: Date.current, views_count: 5)
      CastDailyView.create!(cast: other_cast, view_date: Date.current, views_count: 5)
      sign_in admin

      get admin_analytics_path(page_type: "cast", cast_id: cast.id)

      assert_response :success
      assert_includes @response.body, "#{cast.name} の閲覧数推移"
      assert_not_includes @response.body, "女の子別閲覧数ランキング"
    end

    test "shows the daily total for INDEX/関東/中部 pages and a comparison table" do
      admin = create_user(role: :platform_admin)
      PageDailyView.create!(page_key: "index", view_date: Date.current, views_count: 10)
      PageDailyView.create!(page_key: "kanto", view_date: Date.current, views_count: 5)
      PageDailyView.create!(page_key: "chubu", view_date: Date.current, views_count: 2)
      sign_in admin

      get admin_analytics_path(page_type: "page")

      assert_response :success
      assert_includes @response.body, "INDEXページ の閲覧数推移"
      assert_includes @response.body, "関東ポータル"
      assert_includes @response.body, "中部ポータル"
    end

    test "filtering the page analytics by page_key shows only that page's trend" do
      admin = create_user(role: :platform_admin)
      PageDailyView.create!(page_key: "kanto", view_date: Date.current, views_count: 7)
      sign_in admin

      get admin_analytics_path(page_type: "page", page_key: "kanto")

      assert_response :success
      assert_includes @response.body, "関東ポータル の閲覧数推移"
    end

    test "a shop admin cannot access analytics" do
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get admin_analytics_path

      assert_redirected_to root_path
    end
  end
end
