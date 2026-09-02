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

    test "a shop admin sees the member's SMS verification status" do
      shop = create_shop
      verified_member = create_member(phone_verified_at: Time.current, phone_number: "09012345678")
      verified_membership = ShopMembership.create!(shop: shop, member: verified_member)
      unverified_membership = ShopMembership.create!(shop: shop, member: create_member)
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      get shop_admin_shop_membership_path(verified_membership)
      assert_match "認証済み", response.body
      assert_match "09012345678", response.body

      get shop_admin_shop_membership_path(unverified_membership)
      assert_match "未認証", response.body
    end

    test "shows the shop name, member name, member number, and issue date on the card" do
      shop = create_shop(name: "カード確認店舗")
      membership = ShopMembership.create!(shop: shop, member: create_member(name: "カード確認会員"))
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      get shop_admin_shop_membership_path(membership)

      assert_match "カード確認店舗", response.body
      assert_match "カード確認会員", response.body
      assert_match membership.formatted_member_number, response.body
      assert_match membership.created_at.strftime("%Y/%m/%d"), response.body
    end

    test "a shop admin can bulk-download check-in QR cards for their own casts" do
      shop = create_shop
      create_cast(shop: shop)
      create_cast(shop: shop)
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      get check_in_cards_shop_admin_shop_memberships_path

      assert_response :success
      assert_equal "application/pdf", response.media_type
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
