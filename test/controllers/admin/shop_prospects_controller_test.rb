require "test_helper"

module Admin
  class ShopProspectsControllerTest < ActionDispatch::IntegrationTest
    test "a platform admin can create, update, and delete a prospect" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      post admin_shop_prospects_path, params: { shop_prospect: { name: "候補店舗", phone: "03-0000-0000" } }
      assert_redirected_to admin_shop_prospects_path
      prospect = ShopProspect.find_by(name: "候補店舗")
      assert prospect.present?

      patch admin_shop_prospect_path(prospect), params: { shop_prospect: { status: "contacted" } }
      assert_equal "contacted", prospect.reload.status

      delete admin_shop_prospect_path(prospect)
      assert_not ShopProspect.exists?(prospect.id)
    end

    test "index filters by district_id and paginates" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      kinshicho = ShopProspect.create!(name: "錦糸町店", genre: "デリヘル/錦糸町")
      ShopProspect.create!(name: "浅草店", genre: "ソープ/浅草")

      get admin_shop_prospects_path(district_id: kinshicho.shop_prospect_district_id)

      assert_response :success
      assert_match "錦糸町店", response.body
      assert_no_match "浅草店", response.body
    end

    test "index filters by prefecture" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      ShopProspect.create!(name: "錦糸町店", genre: "デリヘル/錦糸町")
      osaka_district = ShopProspectDistrict.create!(name: "梅田", prefecture: "大阪")
      ShopProspect.create!(name: "梅田店", shop_prospect_district: osaka_district)

      get admin_shop_prospects_path(prefecture: "東京")

      assert_response :success
      assert_match "錦糸町店", response.body
      assert_no_match "梅田店", response.body
    end

    test "a shop admin cannot access the sales prospect screens" do
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get admin_shop_prospects_path

      assert_redirected_to root_path
    end

    test "import creates prospects from an uploaded CSV" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      csv = <<~CSV
        店舗名,ジャンル,電話番号,メールアドレス,URL
        インポート店舗A,ソープ/吉原,03-1111-1111,a@example.com,https://example.com/a
      CSV
      file = Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "prospects.csv")

      post import_admin_shop_prospects_path, params: { file: file }

      assert_redirected_to admin_shop_prospects_path
      assert ShopProspect.exists?(name: "インポート店舗A")
    end

    test "template downloads a CSV with the expected headers" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      get template_admin_shop_prospects_path

      assert_response :success
      assert_match "店舗名", response.body
    end

    test "send_outreach_emails delivers to selected prospects and records the send time" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      prospect = ShopProspect.create!(name: "候補店舗", email: "prospect@example.com")

      assert_emails 1 do
        post send_outreach_emails_admin_shop_prospects_path, params: { shop_prospect_ids: [prospect.id] }
      end

      assert_redirected_to admin_shop_prospects_path
      assert prospect.reload.outreach_email_sent_at.present?
    end

    test "send_outreach_emails advances a not_contacted prospect to contacted" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      prospect = ShopProspect.create!(name: "候補店舗", email: "prospect@example.com", status: :not_contacted)

      post send_outreach_emails_admin_shop_prospects_path, params: { shop_prospect_ids: [prospect.id] }

      assert prospect.reload.contacted?
    end

    test "send_outreach_emails does not move a prospect already further along back to contacted" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      prospect = ShopProspect.create!(name: "候補店舗", email: "prospect@example.com", status: :negotiating)

      post send_outreach_emails_admin_shop_prospects_path, params: { shop_prospect_ids: [prospect.id] }

      assert prospect.reload.negotiating?
    end

    test "export downloads a CSV of the current filter" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      ShopProspect.create!(name: "錦糸町店", genre: "デリヘル/錦糸町")
      ShopProspect.create!(name: "浅草店", genre: "ソープ/浅草")

      get export_admin_shop_prospects_path

      assert_response :success
      assert_match "錦糸町店", response.body
      assert_match "浅草店", response.body
      assert_match "東京ー錦糸町", response.body
    end

    test "export respects the district_id filter" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      kinshicho = ShopProspect.create!(name: "錦糸町店", genre: "デリヘル/錦糸町")
      ShopProspect.create!(name: "浅草店", genre: "ソープ/浅草")

      get export_admin_shop_prospects_path(district_id: kinshicho.shop_prospect_district_id)

      assert_match "錦糸町店", response.body
      assert_no_match "浅草店", response.body
    end

    test "send_outreach_emails skips prospects without an email address" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      prospect = ShopProspect.create!(name: "候補店舗")

      assert_emails 0 do
        post send_outreach_emails_admin_shop_prospects_path, params: { shop_prospect_ids: [prospect.id] }
      end

      assert_nil prospect.reload.outreach_email_sent_at
      assert_match "スキップ", flash[:notice]
    end

    test "send_outreach_emails with no selection shows an alert instead of sending anything" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      assert_emails 0 do
        post send_outreach_emails_admin_shop_prospects_path, params: {}
      end

      assert_redirected_to admin_shop_prospects_path
      assert_equal "送信先の営業先候補を選択してください。", flash[:alert]
    end

    test "a shop admin cannot trigger the outreach send" do
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user
      prospect = ShopProspect.create!(name: "候補店舗", email: "prospect@example.com")

      assert_emails 0 do
        post send_outreach_emails_admin_shop_prospects_path, params: { shop_prospect_ids: [prospect.id] }
      end

      assert_redirected_to root_path
    end

    test "destroy_all deletes every prospect" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      ShopProspect.create!(name: "候補A")
      ShopProspect.create!(name: "候補B")

      delete destroy_all_admin_shop_prospects_path

      assert_redirected_to admin_shop_prospects_path
      assert_equal 0, ShopProspect.count
    end

    test "destroy_all with a status filter only deletes prospects with that status" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      ShopProspect.create!(name: "未接触", status: :not_contacted)
      ShopProspect.create!(name: "商談中", status: :negotiating)

      delete destroy_all_admin_shop_prospects_path, params: { status: "not_contacted" }

      assert_not ShopProspect.exists?(name: "未接触")
      assert ShopProspect.exists?(name: "商談中")
    end

    test "destroy_all with a prefecture filter only deletes prospects in that prefecture" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      ShopProspect.create!(name: "錦糸町店", genre: "デリヘル/錦糸町")
      osaka_district = ShopProspectDistrict.create!(name: "梅田", prefecture: "大阪")
      ShopProspect.create!(name: "梅田店", shop_prospect_district: osaka_district)

      delete destroy_all_admin_shop_prospects_path, params: { prefecture: "東京" }

      assert_not ShopProspect.exists?(name: "錦糸町店")
      assert ShopProspect.exists?(name: "梅田店")
    end

    test "a shop admin cannot bulk-delete sales prospects" do
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user
      ShopProspect.create!(name: "候補店舗")

      delete destroy_all_admin_shop_prospects_path

      assert_redirected_to root_path
      assert_equal 1, ShopProspect.count
    end
  end
end
