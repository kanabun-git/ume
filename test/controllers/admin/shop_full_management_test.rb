require "test_helper"

module Admin
  # Platform admins can now fully manage (not just view) casts, coupons,
  # shifts, shop member ranks/benefits, and shop membership records on a
  # shop's behalf -- mirroring what ShopAdmin::*Controller allows for the
  # shop's own admin -- plus delete a diary entry for moderation.
  class ShopFullManagementTest < ActionDispatch::IntegrationTest
    setup do
      @shop = create_shop
      @admin = create_user(role: :platform_admin)
      sign_in @admin
    end

    test "manages a shop's cast roster end to end" do
      post admin_shop_casts_path(@shop), params: {
        cast: { name: "運営者登録キャスト", age: 22, height: 160, bust: 85, cup: "C", waist: 58, hip: 86 }
      }
      assert_redirected_to admin_shop_casts_path(@shop)
      cast = @shop.casts.find_by(name: "運営者登録キャスト")
      assert cast.present?

      patch admin_shop_cast_path(@shop, cast), params: { cast: { age: 23 } }
      assert_equal 23, cast.reload.age

      delete admin_shop_cast_path(@shop, cast)
      assert_not Cast.exists?(cast.id)
    end

    test "manages a shop's coupons and records manual usage" do
      post admin_shop_coupons_path(@shop), params: {
        coupon: { title: "運営者クーポン", course_name: "60分", regular_price: 20_000, discounted_price: 14_000, valid_from: Date.current }
      }
      assert_redirected_to admin_shop_coupons_path(@shop)
      coupon = @shop.coupons.find_by(title: "運営者クーポン")
      assert coupon.present?

      patch admin_shop_coupon_path(@shop, coupon), params: { coupon: { discounted_price: 12_000 } }
      assert_equal 12_000, coupon.reload.discounted_price

      post admin_shop_coupon_usages_path(@shop, coupon)
      assert_equal 1, coupon.coupon_usages.manual.count

      delete admin_shop_coupon_path(@shop, coupon)
      assert_not Coupon.exists?(coupon.id)
    end

    test "bulk-creates and deletes a shop's shifts" do
      cast = create_cast(shop: @shop, name: "運営者確認キャスト")

      post admin_shop_shifts_path(@shop), params: {
        cast_id: cast.id, start_date: "2026-08-10", end_date: "2026-08-16",
        weekdays: %w[1 3 5], start_time: "18:00", end_time: "23:00"
      }
      assert_redirected_to admin_shop_shifts_path(@shop)
      assert_equal 3, cast.shifts.count

      shift = cast.shifts.first
      delete admin_shop_shift_path(@shop, shift)
      assert_not Shift.exists?(shift.id)
    end

    test "deletes a shop's diary entry for moderation" do
      entry = create_diary_entry(cast: create_cast(shop: @shop))

      delete admin_shop_diary_entry_path(@shop, entry)

      assert_redirected_to admin_shop_diary_entries_path(@shop)
      assert_not DiaryEntry.exists?(entry.id)
    end

    test "manages a shop's member ranks and their benefits" do
      post admin_shop_shop_member_ranks_path(@shop), params: { shop_member_rank: { name: "運営者ランク", min_visit_count: 2 } }
      assert_redirected_to admin_shop_shop_member_ranks_path(@shop)
      rank = @shop.shop_member_ranks.find_by(name: "運営者ランク")
      assert rank.present?

      post admin_shop_shop_member_rank_shop_member_benefits_path(@shop, rank), params: {
        shop_member_benefit: { name: "運営者特典", benefit_type: "discount_ticket" }
      }
      benefit = rank.shop_member_benefits.find_by(name: "運営者特典")
      assert benefit.present?

      patch admin_shop_shop_member_rank_shop_member_benefit_path(@shop, rank, benefit), params: { shop_member_benefit: { name: "更新後特典" } }
      assert_equal "更新後特典", benefit.reload.name

      delete admin_shop_shop_member_rank_shop_member_benefit_path(@shop, rank, benefit)
      assert_not ShopMemberBenefit.exists?(benefit.id)

      delete admin_shop_shop_member_rank_path(@shop, rank)
      assert_not ShopMemberRank.exists?(rank.id)
    end

    test "records incident notes, visits, point redemptions, and marks a benefit grant used" do
      membership = @shop.shop_memberships.create!(member: create_member)

      patch admin_shop_shop_membership_path(@shop, membership), params: {
        shop_membership: { incident_notes: "運営者記録の事故歴" }
      }
      assert_equal "運営者記録の事故歴", membership.reload.incident_notes

      post admin_shop_shop_membership_shop_visits_path(@shop, membership), params: {
        shop_visit: { visited_on: Date.current, points_earned: 100 }
      }
      assert_equal 1, membership.reload.visit_count
      assert_equal 100, membership.points

      post admin_shop_shop_membership_shop_point_redemptions_path(@shop, membership), params: {
        shop_point_redemption: { amount: 40, reason: "運営者による利用" }
      }
      assert_equal 60, membership.reload.points

      rank = @shop.shop_member_ranks.create!(name: "常連", min_visit_count: 1)
      benefit = rank.shop_member_benefits.create!(name: "無料券")
      grant = membership.shop_member_benefit_grants.create!(shop_member_benefit: benefit)

      patch mark_used_admin_shop_shop_membership_shop_member_benefit_grant_path(@shop, membership, grant)
      assert grant.reload.used?
    end

    test "a shop admin cannot access these full-management screens under the admin namespace" do
      shop_admin = create_user(role: :shop_admin, shop: @shop)
      sign_out @admin
      sign_in shop_admin

      post admin_shop_casts_path(@shop), params: { cast: { name: "無効" } }

      assert_redirected_to root_path
    end
  end
end
