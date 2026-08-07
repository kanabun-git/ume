require "test_helper"

module Admin
  class AreasControllerTest < ActionDispatch::IntegrationTest
    test "a platform admin can create, update, and delete an area" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      post admin_areas_path, params: { area: { name: "東京都", slug: "tokyo-test", region: "関東" } }
      assert_redirected_to admin_areas_path
      area = Area.find_by(name: "東京都")
      assert area.present?

      patch admin_area_path(area.id), params: { area: { name: "東京都(更新)" } }
      assert_equal "東京都(更新)", area.reload.name

      delete admin_area_path(area.id)
      assert_not Area.exists?(area.id)
    end

    test "a shop admin cannot access area management" do
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get admin_areas_path

      assert_redirected_to root_path
    end

    test "import creates areas from an uploaded CSV and resolves the parent by slug" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      csv = <<~CSV
        名前,カナ,スラッグ,地方,表示順,親エリアのスラッグ
        インポート県,いんぽーとけん,imported-pref,関東,1,
        インポート市,いんぽーとし,imported-city,,1,imported-pref
      CSV
      file = Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "areas.csv")

      post import_admin_areas_path, params: { file: file }

      assert_redirected_to admin_areas_path
      pref = Area.find_by(slug: "imported-pref")
      city = Area.find_by(slug: "imported-city")
      assert pref.present?
      assert_equal pref.id, city.parent_id
    end

    test "template downloads a CSV with the expected headers" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      get template_admin_areas_path

      assert_response :success
      assert_match "親エリアのスラッグ", response.body
    end

    test "export downloads a CSV of the current areas" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      create_area(slug: "export-target-area")

      get export_admin_areas_path

      assert_response :success
      assert_match "export-target-area", response.body
    end
  end
end
