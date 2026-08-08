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

    test "export downloads a CSV of the current member ranks" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      MemberRank.create!(name: "エクスポート対象ランク", min_approved_count: 20)

      get export_admin_member_ranks_path

      assert_response :success
      assert_match "エクスポート対象ランク", response.body
    end

    test "a platform admin can upload a card image for a rank" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      file = Rack::Test::UploadedFile.new(StringIO.new(png_bytes), "image/png", original_filename: "card.png")

      post admin_member_ranks_path, params: { member_rank: { name: "ゴールド", min_approved_count: 10, card_image: file } }

      rank = MemberRank.find_by(name: "ゴールド")
      assert rank.card_image.attached?
    end

    test "leaving the card image field blank on update does not remove an existing image" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      rank = MemberRank.create!(name: "ゴールド", min_approved_count: 10)
      rank.card_image.attach(io: StringIO.new(png_bytes), filename: "card.png", content_type: "image/png")

      patch admin_member_rank_path(rank), params: { member_rank: { name: "プラチナ" } }

      assert rank.reload.card_image.attached?
    end

    test "uploading a new card image replaces the existing one" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      rank = MemberRank.create!(name: "ゴールド", min_approved_count: 10)
      rank.card_image.attach(io: StringIO.new(png_bytes), filename: "old.png", content_type: "image/png")
      old_blob_id = rank.card_image.blob.id
      new_file = Rack::Test::UploadedFile.new(StringIO.new(png_bytes), "image/png", original_filename: "new.png")

      patch admin_member_rank_path(rank), params: { member_rank: { card_image: new_file } }

      rank.reload
      assert rank.card_image.attached?
      assert_equal "new.png", rank.card_image.filename.to_s
      assert_not_equal old_blob_id, rank.card_image.blob.id
    end

    test "checking remove_card_image clears the existing image" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      rank = MemberRank.create!(name: "ゴールド", min_approved_count: 10)
      rank.card_image.attach(io: StringIO.new(png_bytes), filename: "card.png", content_type: "image/png")

      patch admin_member_rank_path(rank), params: { member_rank: { remove_card_image: "1" } }

      assert_not rank.reload.card_image.attached?
    end

    private

    def png_bytes
      Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")
    end
  end
end
