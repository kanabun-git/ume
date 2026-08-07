require "test_helper"

module ShopAdmin
  class CouponUsagesControllerTest < ActionDispatch::IntegrationTest
    test "a shop admin can view and manually log usage for their own coupon" do
      shop = create_shop
      coupon = shop.coupons.create!(title: "テストクーポン", course_name: "60分", regular_price: 20000, discounted_price: 14000, valid_from: Date.current)
      coupon.coupon_usages.create!(usage_type: :net_reservation)
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      get shop_admin_coupon_usages_path(coupon)
      assert_response :success
      assert_match "1件", response.body

      assert_difference -> { coupon.coupon_usages.manual.count }, 1 do
        post shop_admin_coupon_usages_path(coupon)
      end
      assert_redirected_to shop_admin_coupon_usages_path(coupon)
    end

    test "a shop admin cannot view another shop's coupon usage log" do
      other_coupon = create_shop.coupons.create!(
        title: "他店クーポン", course_name: "60分", regular_price: 20000, discounted_price: 14000, valid_from: Date.current
      )
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get shop_admin_coupon_usages_path(other_coupon)

      assert_response :not_found
    end

    test "a shop admin cannot log usage for another shop's coupon" do
      other_coupon = create_shop.coupons.create!(
        title: "他店クーポン", course_name: "60分", regular_price: 20000, discounted_price: 14000, valid_from: Date.current
      )
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      post shop_admin_coupon_usages_path(other_coupon)

      assert_response :not_found
    end
  end
end
