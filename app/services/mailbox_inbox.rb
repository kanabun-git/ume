require "net/imap"

# The 受信箱を見る screen on メールアドレス管理画面(/mailadmin): reads a
# mailbox's INBOX over IMAP, read-only. No compose/reply/delete/mark-read --
# just enough to confirm mail is arriving and read it without configuring a
# real mail client.
#
# Stateless by design (matches MailboxRoundTripTest): every call opens its
# own IMAP connection with the account's own displayable_password and closes
# it again, rather than keeping a session around between requests.
class MailboxInbox
  class ConnectionError < StandardError; end

  MessageSummary = Struct.new(:uid, :from, :subject, :date, keyword_init: true)
  Message = Struct.new(:uid, :from, :to, :subject, :date, :text_body, :html_body, keyword_init: true)

  # How many of the most recent messages #messages lists. This is a
  # read-only glance at the inbox, not a full mail client, so an unbounded
  # fetch isn't worth the risk of a slow response on a busy mailbox.
  MESSAGE_LIMIT = 50
  OPEN_TIMEOUT = 10

  def initialize(mail_account)
    @mail_account = mail_account
  end

  def messages
    with_imap do |imap|
      imap.select("INBOX")
      uids = imap.uid_search(["ALL"])
      recent_uids = uids.last(MESSAGE_LIMIT).reverse
      return [] if recent_uids.empty?

      imap.uid_fetch(recent_uids, ["ENVELOPE", "UID"])
        .sort_by { |item| -item.attr["UID"] }
        .map { |item| summary_from(item) }
    end
  end

  def message(uid)
    with_imap do |imap|
      imap.select("INBOX")
      data = imap.uid_fetch(uid, "RFC822")
      raise ConnectionError, "メールが見つかりませんでした(削除された可能性があります)。" if data.blank?

      parse_message(uid, data.first.attr["RFC822"])
    end
  end

  private

  def with_imap
    password = @mail_account.displayable_password
    raise ConnectionError, "パスワードを確認できないため受信箱を表示できません(先にパスワードを変更してください)。" if password.blank?

    imap = Net::IMAP.new(
      @mail_account.mail_domain.mail_host,
      port: ::MailDomain::IMAP_PORT,
      ssl: true,
      open_timeout: OPEN_TIMEOUT
    )
    imap.login(@mail_account.address, password)
    yield imap
  rescue ConnectionError
    raise
  rescue StandardError => e
    raise ConnectionError, "受信箱に接続できませんでした: #{e.message.truncate(300)}"
  ensure
    begin
      imap&.logout
    rescue StandardError
      nil
    end
    begin
      imap&.disconnect
    rescue StandardError
      nil
    end
  end

  def summary_from(item)
    envelope = item.attr["ENVELOPE"]
    MessageSummary.new(
      uid: item.attr["UID"],
      from: format_address(envelope.from&.first),
      subject: decode_header(envelope.subject).presence || "(件名なし)",
      date: parse_date(envelope.date)
    )
  end

  def parse_message(uid, raw)
    mail = Mail.read_from_string(raw)
    Message.new(
      uid: uid,
      from: mail.from&.join(", "),
      to: mail.to&.join(", "),
      subject: mail.subject.to_s.presence || "(件名なし)",
      date: mail.date,
      text_body: decode_part(text_part_of(mail)),
      html_body: decode_part(html_part_of(mail))
    )
  end

  def text_part_of(mail)
    return mail.text_part if mail.multipart?

    mail if mail.content_type.to_s.start_with?("text/plain") || mail.content_type.blank?
  end

  def html_part_of(mail)
    return mail.html_part if mail.multipart?

    mail if mail.content_type.to_s.start_with?("text/html")
  end

  # Mail bodies arrive in whatever charset the sender declared (ISO-2022-JP
  # and Shift_JIS are common for Japanese mail, not just UTF-8), so this has
  # to convert explicitly rather than assume UTF-8 -- otherwise Japanese
  # content renders as mojibake or raises on invalid byte sequences.
  def decode_part(part)
    return nil unless part

    charset = part.charset.presence || "UTF-8"
    part.body.decoded.force_encoding(charset).encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
  rescue StandardError
    part.body.decoded.scrub
  end

  def format_address(address)
    return nil unless address

    mailbox = "#{address.mailbox}@#{address.host}"
    name = decode_header(address.name)
    name.present? ? "#{name} <#{mailbox}>" : mailbox
  end

  # IMAP ENVELOPE fields (unlike the `mail` gem's Mail#subject/#from used in
  # #parse_message below) come back as the raw header text, encoded-words
  # and all -- e.g. "=?ISO-2022-JP?B?...?=" -- so list-view summaries need
  # their own RFC 2047 decoding or Japanese subjects/names render as mojibake.
  def decode_header(value)
    return nil if value.nil?

    Mail::Encodings.value_decode(value.to_s).presence || value.to_s
  rescue StandardError
    value.to_s
  end

  def parse_date(date_string)
    Time.zone.parse(date_string.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
