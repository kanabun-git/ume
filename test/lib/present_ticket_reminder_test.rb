require "test_helper"
require "present_ticket_reminder"

class PresentTicketReminderTest < ActiveSupport::TestCase
  test "includes an open ticket from a favorited shop with a deadline within 24 hours" do
    member = create_member
    shop = create_shop
    member.shop_favorites.create!(shop: shop)
    ticket = PresentTicket.create!(shop: shop, name: "まもなく締切", capacity: 1, deadline_at: 12.hours.from_now)

    result = PresentTicketReminder.new(member).upcoming_deadline_tickets

    assert_equal [ticket], result.to_a
  end

  test "excludes a ticket whose deadline is further than 24 hours away" do
    member = create_member
    shop = create_shop
    member.shop_favorites.create!(shop: shop)
    PresentTicket.create!(shop: shop, name: "まだ先", capacity: 1, deadline_at: 3.days.from_now)

    assert_empty PresentTicketReminder.new(member).upcoming_deadline_tickets
  end

  test "excludes a ticket the member has already entered" do
    member = create_member
    shop = create_shop
    member.shop_favorites.create!(shop: shop)
    ticket = PresentTicket.create!(shop: shop, name: "応募済み", capacity: 1, deadline_at: 12.hours.from_now)
    ticket.present_ticket_entries.create!(member: member)

    assert_empty PresentTicketReminder.new(member).upcoming_deadline_tickets
  end

  test "excludes tickets from shops the member hasn't favorited" do
    member = create_member
    PresentTicket.create!(shop: create_shop, name: "無関係の企画", capacity: 1, deadline_at: 12.hours.from_now)

    assert_empty PresentTicketReminder.new(member).upcoming_deadline_tickets
  end
end
