require "test_helper"

module ShopAdmin
  class ShopVisitsControllerTest < ActionDispatch::IntegrationTest
    test "a shop admin can record a visit and it awards points" do
      shop = create_shop
      membership = ShopMembership.create!(shop: shop, member: create_member)
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      post shop_admin_shop_membership_shop_visits_path(membership), params: {
        shop_visit: { visited_on: Date.current, points_earned: 100, memo: "60分コース" }
      }

      assert_redirected_to shop_admin_shop_membership_path(membership)
      assert_equal 1, membership.visit_count
      assert_equal 100, membership.points
    end

    test "a shop admin cannot record a visit for another shop's membership" do
      other_membership = ShopMembership.create!(shop: create_shop, member: create_member)
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      post shop_admin_shop_membership_shop_visits_path(other_membership), params: { shop_visit: { visited_on: Date.current } }

      assert_response :not_found
    end
  end
end
