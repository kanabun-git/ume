namespace :notifications do
  desc "Send favorited-cast diary/shift update digests and present-ticket deadline reminders to members with something new to see. Intended to run once daily via cron/systemd timer (see docs/vps_setup.md)."
  task send_daily: :environment do
    digests_sent = 0
    reminders_sent = 0

    Member.find_each do |member|
      digest = FavoriteUpdateDigest.new(member)
      if digest.any_updates?
        entries = digest.new_diary_entries.to_a
        FavoriteUpdateMailer.digest(member, diary_entries: entries, shifts: digest.todays_shifts.to_a).deliver_now
        DiaryEntry.where(id: entries.map(&:id)).update_all(favorite_notified_at: Time.current)
        digests_sent += 1
      end

      tickets = PresentTicketReminder.new(member).upcoming_deadline_tickets.to_a
      if tickets.any?
        PresentTicketMailer.reminder(member, tickets: tickets).deliver_now
        reminders_sent += 1
      end
    end

    puts "Sent #{digests_sent} favorite-update digest(s) and #{reminders_sent} present-ticket reminder(s)."
  end
end
