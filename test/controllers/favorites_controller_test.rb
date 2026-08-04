require "test_helper"

class FavoritesControllerTest < ActionDispatch::IntegrationTest
  test "a signed-in member can favorite a cast" do
    member = create_member
    cast = create_cast
    sign_in member

    post favorites_path, params: { cast_id: cast.id }

    assert_redirected_to cast_path(cast)
    assert member.reload.favorited?(cast)
  end

  test "favoriting the same cast twice does not raise" do
    member = create_member
    cast = create_cast
    sign_in member

    post favorites_path, params: { cast_id: cast.id }
    post favorites_path, params: { cast_id: cast.id }

    assert_equal 1, member.favorites.where(cast: cast).count
  end

  test "a signed-in member can unfavorite a cast" do
    member = create_member
    cast = create_cast
    member.favorites.create!(cast: cast)
    sign_in member

    delete favorite_path(cast)

    assert_not member.reload.favorited?(cast)
  end

  test "cannot favorite a cast belonging to a suspended shop" do
    member = create_member
    cast = create_cast(shop: create_shop(status: :suspended))
    sign_in member

    post favorites_path, params: { cast_id: cast.id }

    assert_response :not_found
  end

  test "a signed-out visitor is redirected to member login" do
    cast = create_cast

    post favorites_path, params: { cast_id: cast.id }

    assert_redirected_to new_member_session_path
  end
end
