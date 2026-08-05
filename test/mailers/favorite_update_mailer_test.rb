require "test_helper"

class FavoriteUpdateMailerTest < ActionMailer::TestCase
  test "digest lists new diary entries and today's shifts" do
    member = create_member
    cast = create_cast(name: "ゆい")
    entry = create_diary_entry(cast: cast, title: "新着日記タイトル")
    shift = cast.shifts.create!(work_date: Date.current, start_time: "18:00", end_time: "23:00")

    mail = FavoriteUpdateMailer.digest(member, diary_entries: [entry], shifts: [shift])

    assert_equal [member.email], mail.to
    assert_match "お気に入りの更新情報", mail.subject
    assert_match "新着日記タイトル", mail.html_part.body.to_s
    assert_match "18:00", mail.html_part.body.to_s
  end
end
