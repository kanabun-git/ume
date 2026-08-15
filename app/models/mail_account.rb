# A single mailbox (info@example.com) under one of the operated sites.
#
# Rows here are the source of truth: MailboxProvisioner regenerates the mail
# server's Postfix/Dovecot maps from the whole table after every change, so
# "delete the row" is all a deletion needs to be (see app/services/mailbox_provisioner.rb).
class MailAccount < ApplicationRecord
  # Deliberately narrower than what RFC 5321 allows: lowercase letters,
  # digits, dot/underscore/hyphen, not starting or ending with a separator.
  # Everything in here ends up in Postfix/Dovecot map files and in a
  # maildir path, so anything exotic (quotes, spaces, slashes, "..") is
  # rejected at the door rather than escaped later.
  LOCAL_PART_FORMAT = /\A[a-z0-9](?:[a-z0-9._\-]*[a-z0-9])?\z/
  MIN_PASSWORD_LENGTH = 10
  MAX_PASSWORD_LENGTH = 128

  belongs_to :mail_domain

  # The plaintext is only ever held in memory long enough to hash it; the
  # column stores the SHA-512 crypt digest Dovecot authenticates against.
  attr_accessor :password, :password_confirmation

  before_validation :normalize_local_part
  before_validation :apply_password

  validates :local_part,
    presence: true,
    length: { maximum: 64 },
    format: { with: LOCAL_PART_FORMAT, message: "は半角英小文字・数字・記号(. _ -)で入力してください" },
    uniqueness: { scope: :mail_domain_id, message: "は同じドメインに既に登録されています" }
  validates :password, presence: true, on: :create
  validates :password,
    length: { minimum: MIN_PASSWORD_LENGTH, maximum: MAX_PASSWORD_LENGTH },
    confirmation: true,
    allow_blank: true
  # Safety net for any path that saves without going through #password= --
  # skipped when the password itself already failed, so a blank password
  # doesn't report the same problem twice.
  validates :password_hash, presence: true, unless: -> { errors[:password].any? }
  validate :local_part_without_consecutive_dots

  default_scope { order(:local_part) }

  def address
    "#{local_part}@#{mail_domain.domain}"
  end

  # Where this mailbox lives under the virtual mail root, as Postfix's
  # virtual_mailbox_maps wants it (trailing slash = maildir format).
  def maildir_path
    "#{mail_domain.domain}/#{local_part}/"
  end

  # False while the row has been created/edited but the mail server's maps
  # haven't been regenerated from it yet (a failed or not-yet-configured
  # sync), which the management screen surfaces as 未反映.
  def synced?
    synced_at.present? && synced_at >= updated_at
  end

  # SHA-512 crypt ("$6$...") is what Dovecot's passwd-file scheme expects.
  # Returns nil when the platform's crypt(3) doesn't support it (macOS),
  # so the caller can report that instead of silently storing a DES hash.
  def self.sha512_crypt(password)
    digest = password.crypt("$6$#{SecureRandom.alphanumeric(16)}$")
    digest&.start_with?("$6$") ? digest : nil
  end

  private

  def normalize_local_part
    self.local_part = local_part.to_s.strip.downcase.sub(/@.*\z/, "") if local_part.present?
  end

  def apply_password
    return if password.blank?
    return if password_confirmation.present? && password != password_confirmation

    digest = self.class.sha512_crypt(password)
    if digest
      self.password_hash = digest
    else
      errors.add(:password, "を暗号化できませんでした(このサーバーのcrypt(3)がSHA-512に対応していません)")
    end
  end

  # ".." in a local part would still pass LOCAL_PART_FORMAT but is invalid
  # as an address and would produce a surprising maildir path.
  def local_part_without_consecutive_dots
    errors.add(:local_part, "に「..」は使用できません") if local_part.to_s.include?("..")
  end
end
