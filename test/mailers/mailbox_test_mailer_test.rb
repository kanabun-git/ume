require "test_helper"

class MailboxTestMailerTest < ActionMailer::TestCase
  test "test_email is sent from the address being tested and names the site" do
    mail = MailboxTestMailer.test_email(
      from_address: "info@example.com",
      to_address: "operator@example.org",
      site_name: "サイト本体"
    )

    assert_equal ["info@example.com"], mail.from
    assert_equal ["operator@example.org"], mail.to
    assert_match "【送信テスト】サイト本体(info@example.com)", mail.subject
    assert_match "info@example.com", mail.text_part.body.to_s
    assert_match "サイト本体", mail.html_part.body.to_s
  end
end
