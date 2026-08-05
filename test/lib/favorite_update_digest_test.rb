require "test_helper"
require "favorite_update_digest"

class FavoriteUpdateDigestTest < ActiveSupport::TestCase
  test "new_diary_entries only includes not-yet-notified visible entries from favorited casts" do
    member = create_member
    favorite_cast = create_cast
    member.favorites.create!(cast: favorite_cast)
    other_cast = create_cast

    new_entry = create_diary_entry(cast: favorite_cast, title: "新着")
    already_notified = create_diary_entry(cast: favorite_cast, title: "通知済み", favorite_notified_at: Time.current)
    draft_entry = create_diary_entry(cast: favorite_cast, title: "下書き", status: :draft)
    other_casts_entry = create_diary_entry(cast: other_cast, title: "他キャストの日記")

    result = FavoriteUpdateDigest.new(member).new_diary_entries

    assert_equal [new_entry], result.to_a
    assert_not_includes result, already_notified
    assert_not_includes result, draft_entry
    assert_not_includes result, other_casts_entry
  end

  test "todays_shifts only includes today's shifts from favorited casts" do
    member = create_member
    favorite_cast = create_cast
    member.favorites.create!(cast: favorite_cast)
    other_cast = create_cast

    today_shift = favorite_cast.shifts.create!(work_date: Date.current, start_time: "18:00", end_time: "23:00")
    favorite_cast.shifts.create!(work_date: Date.tomorrow, start_time: "18:00", end_time: "23:00")
    other_cast.shifts.create!(work_date: Date.current, start_time: "18:00", end_time: "23:00")

    result = FavoriteUpdateDigest.new(member).todays_shifts

    assert_equal [today_shift], result.to_a
  end

  test "any_updates? is false for a member with no favorites at all" do
    member = create_member

    assert_not FavoriteUpdateDigest.new(member).any_updates?
  end
end
