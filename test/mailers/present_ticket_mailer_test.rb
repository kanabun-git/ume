require "test_helper"

class PresentTicketMailerTest < ActionMailer::TestCase
  test "result_email uses a won subject and body for a winning entry" do
    ticket = PresentTicket.create!(shop: create_shop, name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)
    entry = ticket.present_ticket_entries.create!(member: create_member, status: :won)

    mail = PresentTicketMailer.result_email(entry)

    assert_match "【当選】", mail.subject
    assert_match "当選しました", mail.html_part.body.to_s
  end

  test "result_email uses a lost subject and body for a losing entry" do
    ticket = PresentTicket.create!(shop: create_shop, name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)
    entry = ticket.present_ticket_entries.create!(member: create_member, status: :lost)

    mail = PresentTicketMailer.result_email(entry)

    assert_match "【落選】", mail.subject
    assert_match "落選となりました", mail.html_part.body.to_s
  end

  test "reminder lists each ticket's shop, name, and deadline" do
    member = create_member
    ticket = PresentTicket.create!(shop: create_shop(name: "テスト店舗"), name: "締切間近企画", capacity: 1, deadline_at: 12.hours.from_now)

    mail = PresentTicketMailer.reminder(member, tickets: [ticket])

    assert_equal [member.email], mail.to
    assert_match "テスト店舗", mail.html_part.body.to_s
    assert_match "締切間近企画", mail.html_part.body.to_s
  end
end
