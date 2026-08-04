require "test_helper"

class FavoriteTest < ActiveSupport::TestCase
  test "a member cannot favorite the same cast twice" do
    member = create_member
    cast = create_cast
    member.favorites.create!(cast: cast)

    duplicate = member.favorites.build(cast: cast)

    assert_not duplicate.valid?
  end

  test "the same cast can be favorited by different members" do
    cast = create_cast
    member_a = create_member
    member_b = create_member

    member_a.favorites.create!(cast: cast)
    favorite_b = member_b.favorites.build(cast: cast)

    assert favorite_b.valid?
  end
end
