# The 送信テスト button on メールアドレス管理画面(/mailadmin): sends one mail
# from a registered address to whatever address the operator typed, so they
# can confirm the mailbox actually delivers (SPF/DNS/Postfix all working)
# without going through a real site feature.
#
# `from` is overridden per call rather than using ApplicationMailer's
# default, since verifying that specific sender is the whole point.
class MailboxTestMailer < ApplicationMailer
  def test_email(from_address:, to_address:, site_name:)
    @from_address = from_address
    @site_name = site_name
    @sent_at = Time.current

    mail(
      from: from_address,
      to: to_address,
      subject: "【送信テスト】#{site_name}(#{from_address})"
    )
  end

  # The 送受信テスト button: sent by MailboxRoundTripTest from an address to
  # itself, tagged with a one-time token so that class can search the
  # mailbox's own INBOX via IMAP afterward and confirm the round trip
  # actually completed (not just that delivery didn't raise).
  def round_trip_email(mail_account:, token:)
    @mail_account = mail_account
    @sent_at = Time.current

    mail(
      from: mail_account.address,
      to: mail_account.address,
      subject: "【送受信テスト】#{mail_account.mail_domain.name}(#{mail_account.address})",
      "X-Ume-Roundtrip-Token" => token
    )
  end
end
