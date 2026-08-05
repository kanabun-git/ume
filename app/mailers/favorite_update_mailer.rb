class FavoriteUpdateMailer < ApplicationMailer
  # Sent once per day, at most, by lib/tasks/notifications.rake — never on
  # every single diary post or shift registration, which would be spammy
  # (a shop admin's one bulk shift upload alone can create dozens of rows).
  def digest(member, diary_entries:, shifts:)
    @member = member
    @diary_entries = diary_entries
    @shifts = shifts

    mail(to: @member.email, subject: "お気に入りの更新情報 | FuzokuZero")
  end
end
