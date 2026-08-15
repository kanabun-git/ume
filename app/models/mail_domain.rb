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

  before_validation :normalize_domain

  validates :name, presence: true, length: { maximum: 100 }
  validates :domain,
    presence: true,
    length: { maximum: 253 },
    format: { with: DOMAIN_FORMAT, message: "は「example.com」のような形式で入力してください" },
    uniqueness: { case_sensitive: false, message: "は既に登録されています" }

  default_scope { order(:domain) }

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
end
