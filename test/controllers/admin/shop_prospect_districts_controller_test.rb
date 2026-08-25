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

    test "index offers to register the prefecture first when it has no matching Area at all" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      ShopProspect.create!(name: "候補A", genre: "デリヘル/梅田")
      district = ShopProspectDistrict.find_by!(name: "梅田", prefecture: "東京")
      district.update!(prefecture: "大阪")

      get admin_shop_prospect_districts_path

      assert_response :success
      assert_match "都道府県(大阪)を先に登録", response.body
    end

    test "index offers to add the district to Area once its prefecture already exists there" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      prefecture = Area.create!(name: "東京", slug: "tokyo-districts-test", region: "関東")
      ShopProspect.create!(name: "候補A", genre: "デリヘル/錦糸町")

      get admin_shop_prospect_districts_path

      assert_response :success
      assert_select "a[href=?]", new_admin_area_path(name: "錦糸町", parent_id: prefecture.id), text: "エリアに追加"
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

    test "a shop admin cannot access district management" do
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get admin_shop_prospect_districts_path

      assert_redirected_to root_path
    end
  end
end
