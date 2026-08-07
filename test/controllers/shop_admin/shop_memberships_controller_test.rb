require "test_helper"

module ShopAdmin
  class ShopMembershipsControllerTest < ActionDispatch::IntegrationTest
    test "a shop admin can view their own shop's membership list and detail" do
      shop = create_shop
      membership = ShopMembership.create!(shop: shop, member: create_member)
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      get shop_admin_shop_memberships_path
      assert_response :success

      get shop_admin_shop_membership_path(membership)
      assert_response :success
    end

    test "a shop admin can record incident history and cautions" do
      shop = create_shop
      membership = ShopMembership.create!(shop: shop, member: create_member)
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      patch shop_admin_shop_membership_path(membership), params: {
        shop_membership: { incident_notes: "過去に無断キャンセルあり", caution_notes: "深夜の連絡は避ける" }
      }

      assert_redirected_to shop_admin_shop_membership_path(membership)
      assert_equal "過去に無断キャンセルあり", membership.reload.incident_notes
    end

    test "a shop admin cannot view or edit another shop's membership" do
      other_membership = ShopMembership.create!(shop: create_shop, member: create_member)
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get shop_admin_shop_membership_path(other_membership)

      assert_response :not_found
    end
  end
end
