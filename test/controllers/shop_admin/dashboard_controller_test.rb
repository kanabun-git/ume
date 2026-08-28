require "test_helper"

module ShopAdmin
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    test "shows a preview link to the shop's public page" do
      shop = create_shop
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      get shop_admin_root_path

      assert_select "a[href=?]", shop_path(shop), text: "店舗ページのデザインをプレビュー"
    end
  end
end
