require "test_helper"

class ShopMembershipTest < ActiveSupport::TestCase
  test "record_visit! logs a visit, awards points, and increases visit_count" do
    membership = ShopMembership.create!(shop: create_shop, member: create_member)

    membership.record_visit!(visited_on: Date.current, points_earned: 100, memo: "60分コース")

    assert_equal 1, membership.visit_count
    assert_equal 100, membership.points
    assert_equal "60分コース", membership.shop_visits.first.memo
  end

  test "reaching a rank's min_visit_count grants that rank's benefits exactly once" do
    shop = create_shop
    membership = ShopMembership.create!(shop: shop, member: create_member)
    rank = ShopMemberRank.create!(shop: shop, name: "レギュラー", min_visit_count: 1)
    benefit = ShopMemberBenefit.create!(shop_member_rank: rank, name: "500円割引券")

    membership.record_visit!(visited_on: Date.current)

    assert_equal 1, membership.shop_member_benefit_grants.count
    assert_equal benefit, membership.shop_member_benefit_grants.first.shop_member_benefit
    assert membership.shop_member_benefit_grants.first.unused?

    # A second visit doesn't re-reach the same rank, so no duplicate grant.
    membership.record_visit!(visited_on: Date.current)
    assert_equal 1, membership.shop_member_benefit_grants.count
  end

  test "current_rank and next_rank reflect the visit count against the shop's rank tiers" do
    shop = create_shop
    membership = ShopMembership.create!(shop: shop, member: create_member)
    bronze = ShopMemberRank.create!(shop: shop, name: "ブロンズ", min_visit_count: 1)
    silver = ShopMemberRank.create!(shop: shop, name: "シルバー", min_visit_count: 3)

    assert_nil membership.current_rank
    assert_equal bronze, membership.next_rank

    membership.record_visit!(visited_on: Date.current)
    assert_equal bronze, membership.current_rank
    assert_equal silver, membership.next_rank

    2.times { membership.record_visit!(visited_on: Date.current) }
    assert_equal silver, membership.current_rank
    assert_nil membership.next_rank
  end

  test "redeem_points! deducts a valid amount and rejects an amount over the balance" do
    membership = ShopMembership.create!(shop: create_shop, member: create_member)
    membership.record_visit!(visited_on: Date.current, points_earned: 300)

    assert membership.redeem_points!(200, reason: "ポイント利用: 200円引き")
    assert_equal 100, membership.points

    assert_not membership.redeem_points!(200, reason: "残高不足のはず")
    assert_equal 100, membership.points
  end

  test "a member can only have one membership per shop" do
    shop = create_shop
    member = create_member
    ShopMembership.create!(shop: shop, member: member)

    duplicate = ShopMembership.new(shop: shop, member: member)

    assert_not duplicate.valid?
  end

  test "assigns sequential member numbers scoped to the shop" do
    shop = create_shop
    other_shop = create_shop

    first = ShopMembership.create!(shop: shop, member: create_member)
    second = ShopMembership.create!(shop: shop, member: create_member)
    other_shop_first = ShopMembership.create!(shop: other_shop, member: create_member)

    assert_equal 1, first.member_number
    assert_equal 2, second.member_number
    assert_equal 1, other_shop_first.member_number
  end

  test "formatted_member_number pads to four digits" do
    membership = ShopMembership.create!(shop: create_shop, member: create_member)

    assert_equal "No.0001", membership.formatted_member_number
  end
end
