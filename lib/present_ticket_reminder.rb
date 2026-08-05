# Present tickets from a member's favorited shops whose entry deadline is
# within the next 24 hours, that the member hasn't already entered (see
# lib/tasks/notifications.rake). Reminders are naturally one-shot: once the
# deadline passes the ticket drops out of PresentTicket.open_for_entry, so
# no separate "already reminded" tracking is needed.
class PresentTicketReminder
  attr_reader :member

  def initialize(member)
    @member = member
  end

  def upcoming_deadline_tickets
    shop_ids = member.favorite_shops.ids
    return PresentTicket.none if shop_ids.empty?

    entered_ticket_ids = member.present_ticket_entries.select(:present_ticket_id)

    PresentTicket.open_for_entry
      .where(shop_id: shop_ids)
      .where(deadline_at: Time.current..24.hours.from_now)
      .where.not(id: entered_ticket_ids)
  end
end
