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
        店舗名,電話番号,メールアドレス,掲載サイト名,掲載URL,メモ
        インポート店舗A,03-1111-1111,a@example.com,○○ネット,https://example.com/a,
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
  end
end
