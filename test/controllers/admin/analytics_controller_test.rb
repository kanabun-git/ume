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

    test "a shop admin cannot access analytics" do
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get admin_analytics_path

      assert_redirected_to root_path
    end
  end
end
