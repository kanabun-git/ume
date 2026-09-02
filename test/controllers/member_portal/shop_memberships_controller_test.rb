require "test_helper"

module MemberPortal
  class ShopMembershipsControllerTest < ActionDispatch::IntegrationTest
    test "a member can view their own shop membership's visit history, points, and benefits" do
      shop = create_shop
      member = create_member(phone_verified_at: Time.current)
      membership = ShopMembership.create!(shop: shop, member: member)
      membership.record_visit!(visited_at: Date.current, points_earned: 100, memo: "60分コース")
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

    test "shows the favorited cast's shift/diary status and the shop's present ticket entry status" do
      shop = create_shop
      cast = create_cast(shop: shop, name: "お気に入りキャスト")
      cast.shifts.create!(work_date: Date.current, start_time: "18:00", end_time: "23:00")
      diary_entry = create_diary_entry(cast: cast, title: "最新の日記")
      ticket = PresentTicket.create!(shop: shop, name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)
      member = create_member(phone_verified_at: Time.current)
      member.favorites.create!(cast: cast)
      ticket.present_ticket_entries.create!(member: member)
      membership = ShopMembership.create!(shop: shop, member: member)
      sign_in member

      get member_shop_membership_path(membership)

      assert_response :success
      assert_match cast.name, response.body
      assert_match "本日出勤", response.body
      assert_match diary_entry.title, response.body
      assert_match ticket.name, response.body
      assert_match "抽選待ち", response.body
    end

    test "shows the shop name, member name, member number, and issue date on the card" do
      shop = create_shop(name: "カード確認店舗")
      member = create_member(name: "カード確認会員", phone_verified_at: Time.current)
      membership = ShopMembership.create!(shop: shop, member: member)
      sign_in member

      get member_shop_membership_path(membership)

      assert_match "カード確認店舗", response.body
      assert_match "カード確認会員", response.body
      assert_match membership.formatted_member_number, response.body
      assert_match membership.created_at.strftime("%Y/%m/%d"), response.body
    end

    test "does not show a favorited cast belonging to a different shop" do
      shop = create_shop
      other_shop_cast = create_cast(shop: create_shop, name: "他店のお気に入り")
      member = create_member(phone_verified_at: Time.current)
      member.favorites.create!(cast: other_shop_cast)
      membership = ShopMembership.create!(shop: shop, member: member)
      sign_in member

      get member_shop_membership_path(membership)

      assert_no_match "他店のお気に入り", response.body
    end
  end
end
