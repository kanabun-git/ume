require "test_helper"

class MailboxInboxTest < ActiveSupport::TestCase
  setup do
    @mail_domain = MailDomain.create!(name: "サイト本体", domain: "example.com")
    @mail_account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")
  end

  test "refuses to connect without a readable password" do
    with_password_display(false) do
      error = assert_raises(MailboxInbox::ConnectionError) { MailboxInbox.new(@mail_account).messages }
      assert_match "パスワードを確認できない", error.message
    end
  end

  test "reports a connection failure gracefully instead of raising a network error" do
    @mail_domain.update!(mail_server_host: "127.0.0.1") # fails fast (connection refused), no real network needed

    error = assert_raises(MailboxInbox::ConnectionError) { MailboxInbox.new(@mail_account).messages }
    assert_match "受信箱に接続できませんでした", error.message
  end

  test "message parses a plain-text mail" do
    raw = <<~RAW
      From: sender@example.com
      To: info@example.com
      Subject: プレーンテキストのメール
      Date: Mon, 16 Aug 2026 12:00:00 +0900
      Content-Type: text/plain; charset=UTF-8

      本文です。
    RAW

    inbox = MailboxInbox.new(@mail_account)
    message = inbox.send(:parse_message, 1, raw)

    assert_equal "プレーンテキストのメール", message.subject
    assert_equal "sender@example.com", message.from
    assert_equal "本文です。", message.text_body.strip
    assert_nil message.html_body
  end

  test "message parses a multipart mail and picks out each part" do
    raw = <<~RAW
      From: sender@example.com
      To: info@example.com
      Subject: HTMLメール
      Date: Mon, 16 Aug 2026 12:00:00 +0900
      Content-Type: multipart/alternative; boundary="BOUNDARY"

      --BOUNDARY
      Content-Type: text/plain; charset=UTF-8

      テキスト版です。
      --BOUNDARY
      Content-Type: text/html; charset=UTF-8

      <p>HTML版です。</p><script>alert(1)</script>
      --BOUNDARY--
    RAW

    inbox = MailboxInbox.new(@mail_account)
    message = inbox.send(:parse_message, 1, raw)

    assert_equal "テキスト版です。", message.text_body.strip
    assert_match "HTML版です。", message.html_body
    # Sanitizing happens in the view, not here -- this only confirms the raw
    # HTML is extracted intact for the view to sanitize.
    assert_match "<script>", message.html_body
  end

  test "message decodes a non-UTF-8 charset body without raising" do
    body = "テスト本文".encode("Shift_JIS")
    raw = (<<~RAW).dup.force_encoding("ASCII-8BIT")
      From: sender@example.com
      To: info@example.com
      Subject: Shift_JIS mail
      Date: Mon, 16 Aug 2026 12:00:00 +0900
      Content-Type: text/plain; charset=Shift_JIS

    RAW
    raw << body.dup.force_encoding("ASCII-8BIT")

    inbox = MailboxInbox.new(@mail_account)
    message = inbox.send(:parse_message, 1, raw)

    assert_equal "テスト本文", message.text_body.strip
    assert message.text_body.valid_encoding?
  end

  private

  def with_password_display(available)
    original = Rails.application.config.x.mail_password_display
    Rails.application.config.x.mail_password_display = available
    yield
  ensure
    Rails.application.config.x.mail_password_display = original
  end
end
