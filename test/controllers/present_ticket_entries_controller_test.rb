require "test_helper"

class PresentTicketEntriesControllerTest < ActionDispatch::IntegrationTest
  test "a signed-in, phone-verified member can apply to an open present ticket" do
    shop = create_shop
    ticket = PresentTicket.create!(shop: shop, name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)
    member = create_member(phone_verified_at: Time.current)
    sign_in member

    post present_ticket_entries_path, params: { present_ticket_id: ticket.id }

    assert_equal 1, ticket.present_ticket_entries.where(member: member).count
  end

  test "a member who hasn't completed SMS verification is redirected to verify instead of applying" do
    shop = create_shop
    ticket = PresentTicket.create!(shop: shop, name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)
    member = create_member
    sign_in member

    post present_ticket_entries_path, params: { present_ticket_id: ticket.id }

    assert_redirected_to new_member_phone_verification_path(return_to: shop_path(shop))
    assert_equal 0, ticket.present_ticket_entries.where(member: member).count
  end

  test "cannot apply to a ticket past its deadline" do
    shop = create_shop
    ticket = PresentTicket.create!(shop: shop, name: "締切済み", capacity: 1, deadline_at: 1.day.ago)
    member = create_member
    sign_in member

    post present_ticket_entries_path, params: { present_ticket_id: ticket.id }

    assert_response :not_found
  end

  test "a member can cancel their own pending entry" do
    ticket = PresentTicket.create!(shop: create_shop, name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)
    member = create_member
    entry = ticket.present_ticket_entries.create!(member: member)
    sign_in member

    delete present_ticket_entry_path(entry)

    assert_not PresentTicketEntry.exists?(entry.id)
  end

  test "a member cannot cancel an entry once it has been drawn" do
    ticket = PresentTicket.create!(shop: create_shop, name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)
    member = create_member
    entry = ticket.present_ticket_entries.create!(member: member)
    ticket.draw!
    sign_in member

    delete present_ticket_entry_path(entry)

    assert PresentTicketEntry.exists?(entry.id)
  end

  test "a signed-out visitor is redirected to member login" do
    ticket = PresentTicket.create!(shop: create_shop, name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)

    post present_ticket_entries_path, params: { present_ticket_id: ticket.id }

    assert_redirected_to new_member_session_path
  end
end
