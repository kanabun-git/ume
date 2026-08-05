require "test_helper"

class PresentTicketTest < ActiveSupport::TestCase
  test "draw! picks exactly `capacity` winners and marks the rest lost" do
    ticket = PresentTicket.create!(shop: create_shop, name: "テスト企画", capacity: 2, deadline_at: 1.day.from_now)
    5.times { ticket.present_ticket_entries.create!(member: create_member) }

    assert ticket.draw!

    assert_equal "drawn", ticket.reload.status
    assert_equal 2, ticket.present_ticket_entries.won.count
    assert_equal 3, ticket.present_ticket_entries.lost.count
  end

  test "draw! is a no-op once already drawn" do
    ticket = PresentTicket.create!(shop: create_shop, name: "テスト企画", capacity: 2, deadline_at: 1.day.from_now)
    ticket.present_ticket_entries.create!(member: create_member)
    ticket.draw!

    assert_not ticket.draw!
  end

  test "draw! doesn't blow up when there are fewer entries than capacity" do
    ticket = PresentTicket.create!(shop: create_shop, name: "テスト企画", capacity: 5, deadline_at: 1.day.from_now)
    ticket.present_ticket_entries.create!(member: create_member)

    assert ticket.draw!

    assert_equal 1, ticket.present_ticket_entries.won.count
    assert_equal 0, ticket.present_ticket_entries.lost.count
  end

  test ".open_for_entry excludes tickets past their deadline or already drawn" do
    shop = create_shop
    open_ticket = PresentTicket.create!(shop: shop, name: "受付中", capacity: 1, deadline_at: 1.day.from_now)
    PresentTicket.create!(shop: shop, name: "締切済み", capacity: 1, deadline_at: 1.day.ago)
    drawn_ticket = PresentTicket.create!(shop: shop, name: "抽選済み", capacity: 1, deadline_at: 1.day.from_now)
    drawn_ticket.update!(status: :drawn)

    assert_equal [open_ticket], PresentTicket.open_for_entry.to_a
  end
end
