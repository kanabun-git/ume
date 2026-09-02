require "test_helper"

module ShopAdmin
  class ShopPointTransactionsControllerTest < ActionDispatch::IntegrationTest
    test "a shop admin can manually grant points beyond a simple redemption" do
      shop = create_shop
      membership = ShopMembership.create!(shop: shop, member: create_member)
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      post shop_admin_shop_membership_shop_point_transactions_path(membership), params: {
        shop_point_transaction: { amount: 500, reason: "誕生日ボーナス" }
      }

      assert_redirected_to shop_admin_shop_membership_path(membership)
      assert_equal 500, membership.reload.points
    end

    test "a shop admin can edit a point transaction's amount and reason" do
      shop = create_shop
      membership = ShopMembership.create!(shop: shop, member: create_member)
      transaction = membership.shop_point_transactions.create!(amount: 100, reason: "来店ポイント")
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      patch shop_admin_shop_membership_shop_point_transaction_path(membership, transaction), params: {
        shop_point_transaction: { amount: 50, reason: "修正後" }
      }

      assert_redirected_to shop_admin_shop_membership_path(membership)
      transaction.reload
      assert_equal 50, transaction.amount
      assert_equal "修正後", transaction.reason
    end

    test "a shop admin can delete a mistaken point transaction" do
      shop = create_shop
      membership = ShopMembership.create!(shop: shop, member: create_member)
      transaction = membership.shop_point_transactions.create!(amount: 1000, reason: "誤入力")
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      delete shop_admin_shop_membership_shop_point_transaction_path(membership, transaction)

      assert_redirected_to shop_admin_shop_membership_path(membership)
      assert_equal 0, membership.reload.points
      assert_not ShopPointTransaction.exists?(transaction.id)
    end

    test "a shop admin cannot create a point transaction for another shop's membership" do
      other_membership = ShopMembership.create!(shop: create_shop, member: create_member)
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      post shop_admin_shop_membership_shop_point_transactions_path(other_membership), params: {
        shop_point_transaction: { amount: 100, reason: "不正" }
      }

      assert_response :not_found
      assert_equal 0, other_membership.reload.points
    end

    test "a shop admin cannot delete a point transaction belonging to another shop's membership" do
      other_membership = ShopMembership.create!(shop: create_shop, member: create_member)
      transaction = other_membership.shop_point_transactions.create!(amount: 100, reason: "来店ポイント")
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      delete shop_admin_shop_membership_shop_point_transaction_path(other_membership, transaction)

      assert_response :not_found
      assert ShopPointTransaction.exists?(transaction.id)
    end
  end
end
