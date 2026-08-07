require "test_helper"

module MemberPortal
  class ShopMembershipsControllerTest < ActionDispatch::IntegrationTest
    test "a member can view their own shop membership's visit history, points, and benefits" do
      shop = create_shop
      member = create_member(phone_verified_at: Time.current)
      membership = ShopMembership.create!(shop: shop, member: member)
      membership.record_visit!(visited_on: Date.current, points_earned: 100, memo: "60分コース")
      sign_in member

      get member_shop_membership_path(membership)

      assert_response :success
      assert_match "60分コース", response.body
      assert_match "100pt", response.body
    end

    test "a member cannot view another member's shop membership" do
      other_membership = ShopMembership.create!(shop: create_shop, member: create_member)
      member = create_member(phone_verified_at: Time.current)
      sign_in member

      get member_shop_membership_path(other_membership)

      assert_response :not_found
    end

    test "the shop-internal incident notes are never rendered to the member" do
      shop = create_shop
      member = create_member(phone_verified_at: Time.current)
      membership = ShopMembership.create!(shop: shop, member: member, incident_notes: "無断キャンセル歴あり", caution_notes: "深夜連絡NG")
      sign_in member

      get member_shop_membership_path(membership)

      assert_no_match "無断キャンセル歴あり", response.body
      assert_no_match "深夜連絡NG", response.body
    end
  end
end
