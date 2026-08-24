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

    test "a shop admin cannot access district management" do
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get admin_shop_prospect_districts_path

      assert_redirected_to root_path
    end
  end
end
