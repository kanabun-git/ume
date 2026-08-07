require "test_helper"

class MemberRankTest < ActiveSupport::TestCase
  test "requires a unique min_approved_count" do
    MemberRank.create!(name: "ブロンズ", min_approved_count: 3)
    duplicate = MemberRank.new(name: "べつのランク", min_approved_count: 3)

    assert_not duplicate.valid?
  end

  test ".for_approved_count returns the highest-threshold rank the count qualifies for" do
    bronze = MemberRank.create!(name: "ブロンズ", min_approved_count: 1)
    silver = MemberRank.create!(name: "シルバー", min_approved_count: 5)
    gold = MemberRank.create!(name: "ゴールド", min_approved_count: 10)

    assert_nil MemberRank.for_approved_count(0)
    assert_equal bronze, MemberRank.for_approved_count(1)
    assert_equal bronze, MemberRank.for_approved_count(4)
    assert_equal silver, MemberRank.for_approved_count(5)
    assert_equal gold, MemberRank.for_approved_count(20)
  end

  test "rejects a card_image over 5MB" do
    rank = MemberRank.new(name: "ブロンズ", min_approved_count: 1)
    rank.card_image.attach(io: StringIO.new("a" * 6.megabytes), filename: "big.png", content_type: "image/png")

    assert_not rank.valid?
  end

  test "rejects a card_image that isn't jpeg/png/webp" do
    rank = MemberRank.new(name: "ブロンズ", min_approved_count: 1)
    rank.card_image.attach(io: StringIO.new("not an image"), filename: "evil.exe", content_type: "application/x-msdownload")

    assert_not rank.valid?
  end

  test "accepts a valid card_image" do
    rank = MemberRank.new(name: "ブロンズ", min_approved_count: 1)
    rank.card_image.attach(io: StringIO.new("fake png data"), filename: "card.png", content_type: "image/png")

    assert rank.valid?
  end
end
