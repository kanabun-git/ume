require "test_helper"

module Admin
  class ShopProspectDistrictsControllerTest < ActionDispatch::IntegrationTest
    test "index lists districts with their prospect counts" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      ShopProspect.create!(name: "候補A", genre: "デリヘル/錦糸町")
      ShopProspect.create!(name: "候補B", genre: "ソープ/錦糸町")

      get admin_shop_prospect_districts_path

      assert_response :success
      assert_match "錦糸町", response.body
      assert_match "東京", response.body
    end

    test "a platform admin can correct a district's prefecture" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      district = ShopProspectDistrict.create!(name: "梅田")

      patch admin_shop_prospect_district_path(district), params: { shop_prospect_district: { prefecture: "大阪" } }

      assert_redirected_to admin_shop_prospect_districts_path
      assert_equal "大阪", district.reload.prefecture
    end

    test "index offers a one-click registration button for a district not yet in Area" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      ShopProspect.create!(name: "候補A", genre: "デリヘル/錦糸町")

      get admin_shop_prospect_districts_path

      assert_response :success
      assert_match "エリアに登録", response.body
    end

    test "index shows a district as already registered once a matching child Area exists" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      prefecture = Area.create!(name: "東京", slug: "tokyo-districts-registered-test", region: "関東")
      Area.create!(name: "錦糸町", slug: "kinshicho-districts-test", parent: prefecture)
      ShopProspect.create!(name: "候補A", genre: "デリヘル/錦糸町")

      get admin_shop_prospect_districts_path

      assert_response :success
      assert_match "登録済み", response.body
    end

    test "register_area creates both the prefecture and district Area with one click when neither exists" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      ShopProspect.create!(name: "候補A", genre: "デリヘル/梅田")
      district = ShopProspectDistrict.find_by!(name: "梅田")
      district.update!(prefecture: "大阪")

      post register_area_admin_shop_prospect_district_path(district)

      assert_redirected_to admin_shop_prospect_districts_path
      prefecture_area = Area.find_by(name: "大阪", parent_id: nil)
      assert prefecture_area.present?
      assert_equal "関西", prefecture_area.region
      assert Area.exists?(name: "梅田", parent_id: prefecture_area.id)
    end

    test "register_area only creates the district when its prefecture is already registered" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      prefecture = Area.create!(name: "東京", slug: "tokyo-register-area-test", region: "関東")
      ShopProspect.create!(name: "候補A", genre: "デリヘル/錦糸町")
      district = ShopProspectDistrict.find_by!(name: "錦糸町")

      assert_no_difference -> { Area.where(parent_id: nil).count } do
        post register_area_admin_shop_prospect_district_path(district)
      end

      assert Area.exists?(name: "錦糸町", parent_id: prefecture.id)
    end

    test "register_area refuses to duplicate an already-registered district" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      prefecture = Area.create!(name: "東京", slug: "tokyo-register-area-dup-test", region: "関東")
      Area.create!(name: "錦糸町", slug: "kinshicho-register-area-dup-test", parent: prefecture)
      ShopProspect.create!(name: "候補A", genre: "デリヘル/錦糸町")
      district = ShopProspectDistrict.find_by!(name: "錦糸町")

      assert_no_difference "Area.count" do
        post register_area_admin_shop_prospect_district_path(district)
      end

      assert_redirected_to admin_shop_prospect_districts_path
      assert_equal "既にエリアへ登録済みです。", flash[:alert]
    end

    test "a shop admin cannot register an area" do
      user = create_user(role: :shop_admin, shop: create_shop)
      district = ShopProspectDistrict.create!(name: "梅田", prefecture: "大阪")
      sign_in user

      post register_area_admin_shop_prospect_district_path(district)

      assert_redirected_to root_path
      assert_not Area.exists?(name: "大阪")
    end

    test "a shop admin cannot access district management" do
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get admin_shop_prospect_districts_path

      assert_redirected_to root_path
    end
  end
end
