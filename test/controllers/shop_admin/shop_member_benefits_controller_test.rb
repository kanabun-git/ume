require "test_helper"

module ShopAdmin
  class ShopMemberBenefitsControllerTest < ActionDispatch::IntegrationTest
    test "a shop admin can create, update, and delete a benefit on their own rank" do
      shop = create_shop
      rank = ShopMemberRank.create!(shop: shop, name: "レギュラー", min_visit_count: 1)
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      post shop_admin_shop_member_rank_shop_member_benefits_path(rank), params: {
        shop_member_benefit: { name: "500円割引券", benefit_type: "discount_ticket", description: "次回来店時に利用可" }
      }
      assert_redirected_to shop_admin_shop_member_ranks_path
      benefit = rank.shop_member_benefits.find_by(name: "500円割引券")
      assert benefit.present?

      patch shop_admin_shop_member_rank_shop_member_benefit_path(rank, benefit), params: { shop_member_benefit: { name: "1000円割引券" } }
      assert_equal "1000円割引券", benefit.reload.name

      delete shop_admin_shop_member_rank_shop_member_benefit_path(rank, benefit)
      assert_not ShopMemberBenefit.exists?(benefit.id)
    end

    test "a shop admin cannot manage a benefit on another shop's rank" do
      other_rank = ShopMemberRank.create!(shop: create_shop, name: "他店ランク", min_visit_count: 1)
      other_benefit = ShopMemberBenefit.create!(shop_member_rank: other_rank, name: "他店特典")
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get edit_shop_admin_shop_member_rank_shop_member_benefit_path(other_rank, other_benefit)

      assert_response :not_found
    end
  end
end
