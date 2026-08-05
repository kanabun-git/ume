require "test_helper"

class ShopFavoriteTest < ActiveSupport::TestCase
  test "a member cannot favorite the same shop twice" do
    member = create_member
    shop = create_shop
    member.shop_favorites.create!(shop: shop)

    duplicate = member.shop_favorites.build(shop: shop)

    assert_not duplicate.valid?
  end

  test "the same shop can be favorited by different members" do
    shop = create_shop
    member_a = create_member
    member_b = create_member

    member_a.shop_favorites.create!(shop: shop)
    favorite_b = member_b.shop_favorites.build(shop: shop)

    assert favorite_b.valid?
  end
end
