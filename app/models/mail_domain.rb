# One of the sites the platform operates (サイト本体・キャストポータル・
# その他)、identified by the domain its mail addresses live under. Rows are
# managed from 運営管理画面 > メールアドレス管理 rather than hard-coded, so a
# fourth site can be added later without a deploy.
class MailDomain < ApplicationRecord
  # Each label is 1-63 chars of [a-z0-9-] not starting/ending with "-", and
  # there has to be at least one dot (a bare "localhost" is not a mail
  # domain we can provision).
  LABEL = /[a-z0-9](?:[a-z0-9\-]{0,61}[a-z0-9])?/
  DOMAIN_FORMAT = /\A#{LABEL}(?:\.#{LABEL})+\z/

  has_many :mail_accounts, dependent: :destroy

  # Ports a mail client needs, alongside the hostname below. Standard
  # values for the Dovecot/Postfix setup described in docs/vps_setup.md;
  # shown on the management screen so an operator can copy them into
  # Thunderbird without asking anyone.
  IMAP_PORT = 993
  SMTP_PORT = 587

  before_validation :normalize_domain
  before_validation :normalize_mail_server_host

  validates :name, presence: true, length: { maximum: 100 }
  validates :mail_server_host,
    length: { maximum: 253 },
    format: { with: DOMAIN_FORMAT, message: "は「mail.example.com」のような形式で入力してください" },
    allow_blank: true
  validates :domain,
    presence: true,
    length: { maximum: 253 },
    format: { with: DOMAIN_FORMAT, message: "は「example.com」のような形式で入力してください" },
    uniqueness: { case_sensitive: false, message: "は既に登録されています" }

  default_scope { order(:domain) }

  # What to type into a mail client's 受信/送信サーバー field. Most setups
  # serve mail on the domain itself; a separate host (mail.example.com) is
  # only needed when the operator says so.
  def mail_host
    mail_server_host.presence || domain
  end

  private

  # Domains are case-insensitive, and an admin pasting a URL fragment
  # ("https://example.com/" or " example.com ") shouldn't create a second,
  # subtly different row for the same site.
  def normalize_domain
    return if domain.nil?

    self.domain = domain.to_s.strip.downcase
      .sub(%r{\Ahttps?://}, "")
      .sub(%r{/.*\z}, "")
      .sub(/\A@/, "")
      .sub(/\.\z/, "")
  end

  def normalize_mail_server_host
    self.mail_server_host = mail_server_host.to_s.strip.downcase.presence
  end
end
