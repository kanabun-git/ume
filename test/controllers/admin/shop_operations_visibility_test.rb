require "test_helper"

module Admin
  # Platform admins should be able to view (read-only) everything a shop
  # admin manages for their own shop -- casts, coupons, shifts, diary
  # entries, present ticket campaigns, member ranks/benefits, and shop
  # membership records -- without being able to edit them from here.
  class ShopOperationsVisibilityTest < ActionDispatch::IntegrationTest
    setup do
      @shop = create_shop
      @admin = create_user(role: :platform_admin)
      sign_in @admin
    end

    test "views a shop's cast roster and an individual cast's detail" do
      cast = create_cast(shop: @shop, name: "閲覧確認キャスト")

      get admin_shop_casts_path(@shop)
      assert_response :success
      assert_match cast.name, response.body

      get admin_shop_cast_path(@shop, cast)
      assert_response :success
      assert_match cast.name, response.body
    end

    test "views a shop's coupons and usage log" do
      coupon = @shop.coupons.create!(
        title: "閲覧確認クーポン", course_name: "コース", regular_price: 20_000,
        discounted_price: 15_000, valid_from: Date.current
      )
      coupon.coupon_usages.create!(usage_type: :manual)

      get admin_shop_coupons_path(@shop)
      assert_response :success
      assert_match coupon.title, response.body

      get admin_shop_coupon_path(@shop, coupon)
      assert_response :success
      assert_match "1件", response.body
    end

    test "views a shop's shifts" do
      cast = create_cast(shop: @shop)
      cast.shifts.create!(work_date: Date.current, start_time: "18:00", end_time: "23:00")

      get admin_shop_shifts_path(@shop)
      assert_response :success
      assert_match cast.name, response.body
    end

    test "views a shop's diary entries and an individual entry" do
      entry = create_diary_entry(cast: create_cast(shop: @shop), title: "閲覧確認日記")

      get admin_shop_diary_entries_path(@shop)
      assert_response :success
      assert_match entry.title, response.body

      get admin_shop_diary_entry_path(@shop, entry)
      assert_response :success
      assert_match entry.title, response.body
    end

    test "views a shop's present ticket campaigns and entries" do
      ticket = @shop.present_tickets.create!(name: "閲覧確認企画", capacity: 1, deadline_at: 1.day.from_now)
      member = create_member
      ticket.present_ticket_entries.create!(member: member)

      get admin_shop_present_tickets_path(@shop)
      assert_response :success
      assert_match ticket.name, response.body

      get admin_shop_present_ticket_path(@shop, ticket)
      assert_response :success
      assert_match member.name, response.body
    end

    test "views a shop's member ranks and their benefits" do
      rank = @shop.shop_member_ranks.create!(name: "閲覧確認ランク", min_visit_count: 3)
      rank.shop_member_benefits.create!(name: "割引券A", benefit_type: :discount_ticket)

      get admin_shop_shop_member_ranks_path(@shop)
      assert_response :success
      assert_match rank.name, response.body
      assert_match "割引券A", response.body
    end

    test "views a shop's memberships including visit/point history and benefit grants" do
      member = create_member
      membership = @shop.shop_memberships.create!(member: member, incident_notes: "非常に丁寧な会員")
      membership.shop_visits.create!(visited_on: Date.current, points_earned: 10)
      membership.shop_point_transactions.create!(amount: 10, reason: "来店ポイント")
      rank = @shop.shop_member_ranks.create!(name: "常連", min_visit_count: 1)
      benefit = rank.shop_member_benefits.create!(name: "無料券B", benefit_type: :free_ticket)
      membership.shop_member_benefit_grants.create!(shop_member_benefit: benefit)

      get admin_shop_shop_memberships_path(@shop)
      assert_response :success
      assert_match member.name, response.body

      get admin_shop_shop_membership_path(@shop, membership)
      assert_response :success
      assert_match "非常に丁寧な会員", response.body
      assert_match "無料券B", response.body
    end

    test "a shop admin cannot access these admin-namespaced screens" do
      shop_admin = create_user(role: :shop_admin, shop: @shop)
      sign_out @admin
      sign_in shop_admin

      get admin_shop_casts_path(@shop)

      assert_redirected_to root_path
    end
  end
end
