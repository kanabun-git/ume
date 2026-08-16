require "test_helper"

class MailboxRoundTripTestTest < ActiveSupport::TestCase
  # Stands in for a mail server that rejects the message outright, so the
  # "send itself fails" branch is exercised for real rather than assumed.
  class RejectingDeliveryMethod
    def initialize(settings = {}); end

    def deliver!(_mail)
      raise StandardError, "smtp exploded"
    end
  end
  ActionMailer::Base.add_delivery_method(:round_trip_rejecting, RejectingDeliveryMethod)

  setup do
    @mail_domain = MailDomain.create!(name: "サイト本体", domain: "example.com")
  end

  test "refuses to run without a readable password, and sends nothing" do
    account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

    with_password_display(false) do
      assert_no_emails do
        result = MailboxRoundTripTest.new(account).call

        assert_not result.succeeded?
        assert_match "パスワードを確認できない", result.message
      end
    end
  end

  test "sends the mail, then reports the IMAP failure when the mail server can't be reached" do
    @mail_domain.update!(mail_server_host: "127.0.0.1") # fails fast (connection refused), no real network needed
    account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

    assert_emails 1 do
      result = MailboxRoundTripTest.new(account).call

      assert_not result.succeeded?
      assert_match "受信確認", result.message
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal ["info@example.com"], mail.from
    assert_equal ["info@example.com"], mail.to
    assert_match "送受信テスト", mail.subject
  end

  test "reports a send failure without a receive-side error message" do
    account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

    with_delivery_method(:round_trip_rejecting) do
      result = MailboxRoundTripTest.new(account).call

      assert_not result.succeeded?
      assert_match "送信に失敗しました", result.message
      assert_match "smtp exploded", result.message
    end
  end

  private

  def with_password_display(available)
    original = Rails.application.config.x.mail_password_display
    Rails.application.config.x.mail_password_display = available
    yield
  ensure
    Rails.application.config.x.mail_password_display = original
  end

  def with_delivery_method(method)
    original = ActionMailer::Base.delivery_method
    ActionMailer::Base.delivery_method = method
    yield
  ensure
    ActionMailer::Base.delivery_method = original
  end
end
