require "net/imap"

# The 送受信テスト button on メールアドレス管理画面(/mailadmin): sends one mail
# from a mailbox to itself, then logs into that same mailbox over IMAP and
# confirms the message actually landed in INBOX -- unlike MailboxTestMailer's
# plain send test (which only proves outbound delivery didn't raise, against
# an address this app doesn't control), this proves the whole loop works:
# Postfix accepted and routed it, and the account's own IMAP login/password
# are correct.
#
# Needs the account's plaintext password to log in, so it's unavailable
# wherever MailAccount#displayable_password is (no encryption key configured,
# or the address predates password display) -- #call reports that plainly
# instead of attempting a login it can't make.
class MailboxRoundTripTest
  # How long to keep checking INBOX for the message before giving up. Local
  # delivery through Postfix/Dovecot is normally sub-second, so this mostly
  # exists to absorb the occasional slow tick without making a genuinely
  # broken mailbox hang the request for long.
  RECEIVE_TIMEOUT = 8
  POLL_INTERVAL = 1

  Result = Struct.new(:succeeded, :message, keyword_init: true) do
    def succeeded?
      succeeded
    end
  end

  def initialize(mail_account)
    @mail_account = mail_account
  end

  def call
    password = @mail_account.displayable_password
    if password.blank?
      return Result.new(
        succeeded: false,
        message: "パスワードを確認できないため送受信テストは実行できません" \
          "(サーバーにパスワード表示の設定が無いか、パスワード変更前に登録されたアドレスです)。"
      )
    end

    token = SecureRandom.hex(8)
    deliver(token)
    wait_for_arrival(token, password)
  rescue StandardError => e
    Result.new(succeeded: false, message: "送信に失敗しました: #{e.message.truncate(300)}")
  end

  private

  def deliver(token)
    ::MailboxTestMailer.round_trip_email(mail_account: @mail_account, token: token).deliver_now
  end

  def wait_for_arrival(token, password)
    deadline = Time.current + RECEIVE_TIMEOUT

    loop do
      return Result.new(succeeded: true, message: "送信・受信ともに成功しました。") if arrived?(token, password)
      return Result.new(
        succeeded: false,
        message: "送信は成功しましたが、#{RECEIVE_TIMEOUT}秒待っても受信箱で確認できませんでした。" \
          "メールサーバーのログ(/var/log/mail.log)を確認してください。"
      ) if Time.current >= deadline

      sleep POLL_INTERVAL
    end
  rescue StandardError => e
    Result.new(
      succeeded: false,
      message: "送信は成功しましたが、受信確認(IMAP接続)に失敗しました: #{e.message.truncate(300)}"
    )
  end

  def arrived?(token, password)
    imap = Net::IMAP.new(@mail_account.mail_domain.mail_host, port: ::MailDomain::IMAP_PORT, ssl: true)
    imap.login(@mail_account.address, password)
    imap.select("INBOX")
    imap.search(["HEADER", "X-Ume-Roundtrip-Token", token]).any?
  ensure
    imap&.logout
    imap&.disconnect
  end
end
