require "test_helper"

class ShopFavoritesControllerTest < ActionDispatch::IntegrationTest
  test "a signed-in member can favorite a shop" do
    member = create_member
    shop = create_shop
    sign_in member

    post shop_favorites_path, params: { shop_id: shop.id }

    assert_redirected_to shop_path(shop)
    assert member.reload.favorited_shop?(shop)
  end

  test "favoriting the same shop twice does not raise" do
    member = create_member
    shop = create_shop
    sign_in member

    post shop_favorites_path, params: { shop_id: shop.id }
    post shop_favorites_path, params: { shop_id: shop.id }

    assert_equal 1, member.shop_favorites.where(shop: shop).count
  end

  test "a signed-in member can unfavorite a shop" do
    member = create_member
    shop = create_shop
    member.shop_favorites.create!(shop: shop)
    sign_in member

    delete shop_favorite_path(shop)

    assert_not member.reload.favorited_shop?(shop)
  end

  test "cannot favorite a suspended shop" do
    member = create_member
    shop = create_shop(status: :suspended)
    sign_in member

    post shop_favorites_path, params: { shop_id: shop.id }

    assert_response :not_found
  end

  test "a signed-out visitor is redirected to member login" do
    shop = create_shop

    post shop_favorites_path, params: { shop_id: shop.id }

    assert_redirected_to new_member_session_path
  end
end
