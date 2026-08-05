require "test_helper"

module ShopAdmin
  class ShopsControllerTest < ActionDispatch::IntegrationTest
    test "a shop admin can set their own PR badge display period" do
      shop = create_shop
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      patch shop_admin_shop_path, params: { shop: { pr_badge_until: 1.day.from_now } }

      assert_redirected_to shop_admin_root_path
      assert shop.reload.pr_badge_active?
    end

    test "a shop admin cannot change fields reserved for the platform admin" do
      shop = create_shop
      other_plan = create_plan
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      patch shop_admin_shop_path, params: { shop: { name: "改名後", plan_id: other_plan.id } }

      assert_not_equal "改名後", shop.reload.name
      assert_not_equal other_plan, shop.plan
    end
  end
end
