require "test_helper"

module ShopAdmin
  class CouponsControllerTest < ActionDispatch::IntegrationTest
    test "a shop admin can create, update, and delete their own coupon" do
      shop = create_shop
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      post shop_admin_coupons_path, params: {
        coupon: {
          title: "テストクーポン", course_name: "60分コース",
          regular_price: 20000, discounted_price: 14000, valid_from: Date.current
        }
      }
      assert_redirected_to shop_admin_coupons_path
      coupon = shop.coupons.find_by(title: "テストクーポン")
      assert coupon.present?

      patch shop_admin_coupon_path(coupon), params: { coupon: { discounted_price: 12000 } }
      assert_equal 12000, coupon.reload.discounted_price

      delete shop_admin_coupon_path(coupon)
      assert_not Coupon.exists?(coupon.id)
    end

    test "a shop admin cannot manage another shop's coupon" do
      other_coupon = create_shop.coupons.create!(
        title: "他店クーポン", course_name: "60分", regular_price: 20000, discounted_price: 14000, valid_from: Date.current
      )
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get edit_shop_admin_coupon_path(other_coupon)

      assert_response :not_found
    end

    test "invalid coupon params re-render the form with errors" do
      shop = create_shop
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      post shop_admin_coupons_path, params: {
        coupon: {
          title: "不正クーポン", course_name: "60分コース",
          regular_price: 10000, discounted_price: 10000, valid_from: Date.current
        }
      }

      assert_response :unprocessable_entity
      assert_not Coupon.exists?(title: "不正クーポン")
    end
  end
end
