require "test_helper"

class MemberTest < ActiveSupport::TestCase
  test "requires a name" do
    member = Member.new(email: "test@example.com", password: "password1234", password_confirmation: "password1234")

    assert_not member.valid?
    assert_includes member.errors.attribute_names, :name
  end

  test "#favorited? reflects whether the member has favorited the cast" do
    member = create_member
    cast = create_cast
    other_cast = create_cast

    member.favorites.create!(cast: cast)

    assert member.favorited?(cast)
    assert_not member.favorited?(other_cast)
  end
end
