require "test_helper"

module ShopAdmin
  class ShopMemberRanksControllerTest < ActionDispatch::IntegrationTest
    test "a shop admin can create, update, and delete their own shop's rank" do
      shop = create_shop
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      post shop_admin_shop_member_ranks_path, params: { shop_member_rank: { name: "レギュラー", min_visit_count: 1 } }
      assert_redirected_to shop_admin_shop_member_ranks_path
      rank = shop.shop_member_ranks.find_by(name: "レギュラー")
      assert rank.present?

      patch shop_admin_shop_member_rank_path(rank), params: { shop_member_rank: { name: "ゴールド" } }
      assert_equal "ゴールド", rank.reload.name

      delete shop_admin_shop_member_rank_path(rank)
      assert_not ShopMemberRank.exists?(rank.id)
    end

    test "a shop admin cannot manage another shop's rank" do
      other_rank = ShopMemberRank.create!(shop: create_shop, name: "他店ランク", min_visit_count: 1)
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get edit_shop_admin_shop_member_rank_path(other_rank)

      assert_response :not_found
    end
  end
end
