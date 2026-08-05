require "test_helper"

class ShopDailyViewTest < ActiveSupport::TestCase
  test ".record! creates a row for today on first call and increments it after" do
    shop = create_shop

    ShopDailyView.record!(shop)
    daily = ShopDailyView.record!(shop)

    assert_equal 2, daily.views_count
    assert_equal 1, ShopDailyView.where(shop: shop, view_date: Date.current).count
  end

  test "a shop cannot have two rows for the same day" do
    shop = create_shop
    ShopDailyView.create!(shop: shop, view_date: Date.current, views_count: 1)

    duplicate = ShopDailyView.new(shop: shop, view_date: Date.current, views_count: 1)

    assert_not duplicate.valid?
  end
end
