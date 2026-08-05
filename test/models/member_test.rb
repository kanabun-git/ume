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

  test "#favorited_shop? reflects whether the member has favorited the shop" do
    member = create_member
    shop = create_shop
    other_shop = create_shop

    member.shop_favorites.create!(shop: shop)

    assert member.favorited_shop?(shop)
    assert_not member.favorited_shop?(other_shop)
  end

  test "#approved_review_count only counts this member's approved reviews" do
    member = create_member
    shop = create_shop
    shop.reviews.create!(member: member, reviewer_name: "A", rating: 5, body: "承認済み1", status: :approved)
    shop.reviews.create!(member: member, reviewer_name: "A", rating: 4, body: "承認済み2", status: :approved)
    shop.reviews.create!(member: member, reviewer_name: "A", rating: 3, body: "承認待ち", status: :pending)
    shop.reviews.create!(reviewer_name: "B", rating: 5, body: "他人の承認済み", status: :approved)

    assert_equal 2, member.approved_review_count
  end

  test "#rank and #next_rank reflect the member's approved review count" do
    MemberRank.create!(name: "ブロンズ", min_approved_count: 1)
    gold = MemberRank.create!(name: "ゴールド", min_approved_count: 3)
    member = create_member
    shop = create_shop
    2.times { |i| shop.reviews.create!(member: member, reviewer_name: "A", rating: 5, body: "口コミ#{i}", status: :approved) }

    assert_equal "ブロンズ", member.rank.name
    assert_equal gold, member.next_rank
  end
end
