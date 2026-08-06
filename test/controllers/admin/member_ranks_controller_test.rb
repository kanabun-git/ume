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

    test "import creates member ranks from an uploaded CSV" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      csv = <<~CSV
        ランク名,必要承認件数
        インポートランク,7
      CSV
      file = Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "ranks.csv")

      post import_admin_member_ranks_path, params: { file: file }

      assert_redirected_to admin_member_ranks_path
      assert MemberRank.exists?(name: "インポートランク")
    end

    test "template downloads a CSV with the expected headers" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      get template_admin_member_ranks_path

      assert_response :success
      assert_match "ランク名", response.body
    end
  end
end
