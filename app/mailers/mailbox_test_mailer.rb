# The 送信テスト button on 運営管理画面 > メールアドレス管理: sends one mail
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
end
