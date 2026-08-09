require "test_helper"

module MemberPortal
  class MypageControllerTest < ActionDispatch::IntegrationTest
    test "lists favorited casts with today's shift status and latest diary entry" do
      member = create_member
      cast = create_cast(name: "お気に入りキャスト")
      cast.shifts.create!(work_date: Date.current, start_time: "18:00", end_time: "23:00")
      entry = create_diary_entry(cast: cast, title: "最新の日記")
      member.favorites.create!(cast: cast)
      sign_in member

      get member_root_path

      assert_response :success
      assert_match cast.name, response.body
      assert_match "本日出勤", response.body
      assert_match entry.title, response.body
    end

    test "shows an off-duty message when the favorited cast has no shift today" do
      member = create_member
      cast = create_cast(name: "本日休みキャスト")
      member.favorites.create!(cast: cast)
      sign_in member

      get member_root_path

      assert_match "本日の出勤予定なし", response.body
    end

    test "excludes a favorited cast whose shop has since been suspended" do
      member = create_member
      cast = create_cast(shop: create_shop(status: :suspended), name: "停止店お気に入りキャスト")
      member.favorites.create!(cast: cast)
      sign_in member

      get member_root_path

      assert_response :success
      assert_no_match cast.name, response.body
    end

    test "redirects a signed-out visitor to member login" do
      get member_root_path

      assert_redirected_to new_member_session_path
    end

    test "shows a card overlaying the shop name, member name, number, and issue date for each shop membership" do
      shop = create_shop(name: "カード確認店舗")
      member = create_member(name: "カード確認会員")
      membership = ShopMembership.create!(shop: shop, member: member)
      sign_in member

      get member_root_path

      assert_response :success
      assert_match "member-card-visual", response.body
      assert_match "カード確認店舗", response.body
      assert_match "カード確認会員", response.body
      assert_match membership.formatted_member_number, response.body
    end

    test "shows a guidance message instead of a card when the member has no shop membership yet" do
      member = create_member
      sign_in member

      get member_root_path

      assert_no_match "member-card-visual", response.body
      assert_match "まだ店舗会員証に登録した店舗がありません", response.body
    end

    test "shows the member's rank-specific card image instead of the site-wide one" do
      SiteSetting.instance.membership_card_image.attach(**png_upload(filename: "site-wide.png"))
      rank = MemberRank.create!(name: "ゴールド", min_approved_count: 0)
      rank.card_image.attach(**png_upload(filename: "gold-card.png"))
      member = create_member
      ShopMembership.create!(shop: create_shop, member: member)
      sign_in member

      get member_root_path

      assert_match "gold-card", response.body
      assert_no_match "site-wide", response.body
    end

    test "falls back to the site-wide card image when the member's rank has no card image" do
      SiteSetting.instance.membership_card_image.attach(**png_upload(filename: "site-wide.png"))
      MemberRank.create!(name: "ブロンズ", min_approved_count: 0)
      member = create_member
      ShopMembership.create!(shop: create_shop, member: member)
      sign_in member

      get member_root_path

      assert_match "site-wide", response.body
    end
  end
end
