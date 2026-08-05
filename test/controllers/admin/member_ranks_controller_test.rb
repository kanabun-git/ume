require "test_helper"

module Admin
  class MemberRanksControllerTest < ActionDispatch::IntegrationTest
    test "a platform admin can create, update, and delete a member rank" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      post admin_member_ranks_path, params: { member_rank: { name: "ブロンズ", min_approved_count: 1 } }
      assert_redirected_to admin_member_ranks_path
      rank = MemberRank.find_by(name: "ブロンズ")
      assert rank.present?

      patch admin_member_rank_path(rank), params: { member_rank: { name: "シルバー" } }
      assert_equal "シルバー", rank.reload.name

      delete admin_member_rank_path(rank)
      assert_not MemberRank.exists?(rank.id)
    end

    test "a shop admin cannot access member rank management" do
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get admin_member_ranks_path

      assert_redirected_to root_path
    end
  end
end
