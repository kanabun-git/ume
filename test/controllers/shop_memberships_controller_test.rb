require "test_helper"

class ShopMembershipsControllerTest < ActionDispatch::IntegrationTest
  test "a phone-verified member can join a shop's membership program" do
    shop = create_shop
    member = create_member(phone_verified_at: Time.current)
    sign_in member

    post shop_shop_membership_path(shop)

    membership = member.shop_memberships.find_by(shop: shop)
    assert membership.present?
    assert_redirected_to member_shop_membership_path(membership)
  end

  test "joining twice does not create a second membership" do
    shop = create_shop
    member = create_member(phone_verified_at: Time.current)
    sign_in member
    post shop_shop_membership_path(shop)

    post shop_shop_membership_path(shop)

    assert_equal 1, member.shop_memberships.where(shop: shop).count
  end

  test "a member who hasn't completed SMS verification is redirected to verify instead of joining" do
    shop = create_shop
    member = create_member
    sign_in member

    post shop_shop_membership_path(shop)

    assert_redirected_to new_member_phone_verification_path(return_to: shop_path(shop))
    assert_not member.shop_memberships.exists?(shop: shop)
  end
end
