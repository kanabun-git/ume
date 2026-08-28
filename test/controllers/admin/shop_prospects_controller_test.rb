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

    test "index filters by district_id" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      kinshicho = ShopProspect.create!(name: "錦糸町店", genre: "デリヘル/錦糸町")
      ShopProspect.create!(name: "浅草店", genre: "ソープ/浅草")

      get admin_shop_prospects_path(district_id: kinshicho.shop_prospect_district_id)

      assert_response :success
      assert_match "錦糸町店", response.body
      assert_no_match "浅草店", response.body
    end

    test "index groups prospects into a collapsible section per district" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      ShopProspect.create!(name: "錦糸町店", genre: "デリヘル/錦糸町")
      osaka_district = ShopProspectDistrict.create!(name: "梅田", prefecture: "大阪")
      ShopProspect.create!(name: "梅田店", shop_prospect_district: osaka_district)

      get admin_shop_prospects_path

      assert_response :success
      assert_select "details.prospect-group", count: 2
      assert_select "details.prospect-group summary", text: /東京ー錦糸町/
      assert_select "details.prospect-group summary", text: /大阪ー梅田/
    end

    test "index shows the outreach click rate and click-to-inquiry conversion count" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      clicked_with_inquiry = ShopProspect.create!(name: "成約候補", email: "a@example.com",
        outreach_email_sent_at: 2.days.ago, outreach_link_clicked_at: 1.day.ago)
      ShopInquiry.create!(shop_name: "新規店舗", contact_name: "担当太郎", email: "owner@example.com",
        phone: "03-1111-2222", shop_prospect: clicked_with_inquiry)
      ShopProspect.create!(name: "クリックのみ候補", email: "b@example.com",
        outreach_email_sent_at: 2.days.ago, outreach_link_clicked_at: 1.day.ago)
      ShopProspect.create!(name: "未クリック候補", email: "c@example.com", outreach_email_sent_at: 2.days.ago)

      get admin_shop_prospects_path

      assert_response :success
      assert_select "h2", text: /営業メール実績/
      assert_match(/送信数.*<strong>3<\/strong>件/m, response.body)
      assert_match(/クリック数.*<strong>2<\/strong>件/m, response.body)
      assert_match(/クリックから掲載のお問い合わせにつながった件数.*<strong>1<\/strong>件/m, response.body)
    end

    test "index click stats ignore the sent/not_sent list filter" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      ShopProspect.create!(name: "送信済み候補", email: "a@example.com",
        outreach_email_sent_at: 1.day.ago, outreach_link_clicked_at: 1.day.ago)
      ShopProspect.create!(name: "未送信候補", email: "b@example.com")

      get admin_shop_prospects_path(sent: "not_sent")

      assert_response :success
      assert_no_match "送信済み候補", response.body
      assert_match "未送信候補", response.body
      assert_match(/送信数.*<strong>1<\/strong>件/m, response.body)
      assert_match(/クリック数.*<strong>1<\/strong>件/m, response.body)
    end

    test "index buckets daily click stats by the day the email was sent" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      ShopProspect.create!(name: "候補店舗", email: "a@example.com",
        outreach_email_sent_at: 2.days.ago, outreach_link_clicked_at: Time.current)

      get admin_shop_prospects_path

      assert_response :success
      assert_match "#{2.days.ago.to_date.strftime('%Y-%m-%d')}: 送信1件中1件クリック(100.0%)", response.body
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

    test "index highlights a prospect that has a linked inquiry" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      prospect = ShopProspect.create!(name: "問い合わせ済み候補", email: "prospect@example.com")
      ShopProspect.create!(name: "未反応候補", email: "other@example.com")
      ShopInquiry.create!(shop_name: "新規店舗", contact_name: "担当太郎", email: "owner@example.com", phone: "03-1111-2222", shop_prospect: prospect)

      get admin_shop_prospects_path

      assert_response :success
      assert_select "td.text-danger", text: "問い合わせ済み候補"
      assert_select "a.text-danger", text: /問い合わせあり/
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

    test "send_outreach_emails keeps processing the rest of the batch even if one recipient's send raises" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      bad = ShopProspect.create!(name: "問題のある候補", email: "bad@example.com")
      good = ShopProspect.create!(name: "正常な候補", email: "good@example.com")
      original_outreach_email = ShopProspectMailer.method(:outreach_email)

      ShopProspectMailer.define_singleton_method(:outreach_email) do |prospect|
        raise StandardError, "boom" if prospect.id == bad.id
        original_outreach_email.call(prospect)
      end

      begin
        post send_outreach_emails_admin_shop_prospects_path, params: { shop_prospect_ids: [bad.id, good.id] }
      ensure
        ShopProspectMailer.define_singleton_method(:outreach_email, original_outreach_email)
      end

      assert_redirected_to admin_shop_prospects_path
      assert good.reload.outreach_email_sent_at.present?
      assert_nil bad.reload.outreach_email_sent_at
      assert_match "1件は送信に失敗しました", flash[:notice]
    end

    test "index filters by outreach email sent status" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      sent = ShopProspect.create!(name: "送信済み候補", outreach_email_sent_at: 1.day.ago)
      not_sent = ShopProspect.create!(name: "未送信候補")

      get admin_shop_prospects_path(sent: "sent")
      assert_match "送信済み候補", response.body
      assert_no_match "未送信候補", response.body

      get admin_shop_prospects_path(sent: "not_sent")
      assert_no_match "送信済み候補", response.body
      assert_match "未送信候補", response.body
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
