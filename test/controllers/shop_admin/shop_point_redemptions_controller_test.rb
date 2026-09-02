require "test_helper"

module ShopAdmin
  class ShopPointRedemptionsControllerTest < ActionDispatch::IntegrationTest
    test "a shop admin can redeem points within the balance" do
      shop = create_shop
      membership = ShopMembership.create!(shop: shop, member: create_member)
      membership.record_visit!(visited_at: Date.current, points_earned: 300)
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      post shop_admin_shop_membership_shop_point_redemptions_path(membership), params: {
        shop_point_redemption: { amount: 200, reason: "200円引きに利用" }
      }

      assert_redirected_to shop_admin_shop_membership_path(membership)
      assert_equal 100, membership.points
    end

    test "redeeming more points than the balance fails without changing it" do
      shop = create_shop
      membership = ShopMembership.create!(shop: shop, member: create_member)
      membership.record_visit!(visited_at: Date.current, points_earned: 50)
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      post shop_admin_shop_membership_shop_point_redemptions_path(membership), params: {
        shop_point_redemption: { amount: 200, reason: "残高不足" }
      }

      assert_redirected_to shop_admin_shop_membership_path(membership)
      assert_equal 50, membership.points
    end
  end
end
