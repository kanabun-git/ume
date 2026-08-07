class PhoneVerificationCode < ApplicationRecord
  belongs_to :member

  validates :phone_number, presence: true
  validates :code, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where(consumed_at: nil).where("expires_at > ?", Time.current) }

  CODE_LENGTH = 6
  EXPIRY = 10.minutes

  # Issues a fresh code, superseding any still-active one for this member
  # so only the most recently sent code can be accepted.
  def self.issue!(member:, phone_number:)
    member.phone_verification_codes.active.update_all(consumed_at: Time.current)
    create!(
      member: member,
      phone_number: phone_number,
      code: format("%0#{CODE_LENGTH}d", SecureRandom.random_number(10**CODE_LENGTH)),
      expires_at: EXPIRY.from_now
    )
  end

  def consumed?
    consumed_at.present?
  end

  def expired?
    expires_at < Time.current
  end
end
