require "test_helper"

class PresentTicketEntryTest < ActiveSupport::TestCase
  test "a member cannot enter the same present ticket twice" do
    ticket = PresentTicket.create!(shop: create_shop, name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)
    member = create_member
    ticket.present_ticket_entries.create!(member: member)

    duplicate = ticket.present_ticket_entries.build(member: member)

    assert_not duplicate.valid?
  end
end
