# Computes what's new for a member's favorited casts since the last digest
# run (see lib/tasks/notifications.rake) — new diary entries, and today's
# shift schedule. Read-only; the caller marks entries notified once the
# mail actually goes out (see FavoriteUpdateMailer#digest).
class FavoriteUpdateDigest
  attr_reader :member

  def initialize(member)
    @member = member
  end

  def new_diary_entries
    cast_ids = member.favorite_casts.ids
    return DiaryEntry.none if cast_ids.empty?

    DiaryEntry.visible.where(cast_id: cast_ids, favorite_notified_at: nil)
  end

  def todays_shifts
    cast_ids = member.favorite_casts.ids
    return Shift.none if cast_ids.empty?

    Shift.scheduled.where(cast_id: cast_ids, work_date: Date.current)
  end

  def any_updates?
    new_diary_entries.exists? || todays_shifts.exists?
  end
end
