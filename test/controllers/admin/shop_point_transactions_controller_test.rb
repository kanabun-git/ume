require "test_helper"

module Admin
  class ShopPointTransactionsControllerTest < ActionDispatch::IntegrationTest
    test "a platform admin can manually grant, edit, and delete a shop membership's points" do
      admin = create_user(role: :platform_admin)
      shop = create_shop
      membership = ShopMembership.create!(shop: shop, member: create_member)
      sign_in admin

      post admin_shop_shop_membership_shop_point_transactions_path(shop, membership), params: {
        shop_point_transaction: { amount: 300, reason: "運営者による付与" }
      }
      assert_redirected_to admin_shop_shop_membership_path(shop, membership)
      assert_equal 300, membership.reload.points

      transaction = membership.shop_point_transactions.first
      patch admin_shop_shop_membership_shop_point_transaction_path(shop, membership, transaction), params: {
        shop_point_transaction: { amount: 200, reason: "修正" }
      }
      assert_equal 200, membership.reload.points

      delete admin_shop_shop_membership_shop_point_transaction_path(shop, membership, transaction)
      assert_equal 0, membership.reload.points
    end

    test "a shop admin cannot manage point transactions under the admin namespace" do
      shop = create_shop
      shop_admin = create_user(role: :shop_admin, shop: shop)
      membership = ShopMembership.create!(shop: shop, member: create_member)
      sign_in shop_admin

      post admin_shop_shop_membership_shop_point_transactions_path(shop, membership), params: {
        shop_point_transaction: { amount: 100, reason: "不正" }
      }

      assert_redirected_to root_path
      assert_equal 0, membership.reload.points
    end
  end
end
