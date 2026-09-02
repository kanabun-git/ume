require "test_helper"

module ShopAdmin
  class ShopMemberBenefitGrantsControllerTest < ActionDispatch::IntegrationTest
    test "a shop admin can mark a granted benefit as used" do
      shop = create_shop
      membership = ShopMembership.create!(shop: shop, member: create_member)
      rank = ShopMemberRank.create!(shop: shop, name: "レギュラー", min_visit_count: 1)
      ShopMemberBenefit.create!(shop_member_rank: rank, name: "500円割引券")
      membership.record_visit!(visited_at: Date.current)
      grant = membership.shop_member_benefit_grants.first
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      patch mark_used_shop_admin_shop_membership_shop_member_benefit_grant_path(membership, grant)

      assert_redirected_to shop_admin_shop_membership_path(membership)
      assert grant.reload.used?
    end
  end
end
