class ShopInquiry < ApplicationRecord
  # Public, unauthenticated form (only a honeypot field guards it -- see
  # ShopInquiriesController#create) -- this cooldown is the same lightweight
  # anti-spam pattern as Review's rate_limit, so a script that gets past the
  # honeypot still can't trigger unlimited admin-notification emails.
  GLOBAL_COOLDOWN = 1.minute

  belongs_to :shop_prospect, optional: true

  enum :status, { pending: 0, in_progress: 1, closed: 2 }, default: :pending

  validates :shop_name, presence: true
  validates :contact_name, presence: true
  validates :email, presence: true
  validates :phone, presence: true
  validate :rate_limit, on: :create

  default_scope { order(created_at: :desc) }

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def archived?
    archived_at.present?
  end

  # Drives the bold-red 店舗名 highlight on 掲載のお問い合わせ管理's index --
  # a lead that's gone unreplied for over a day is easy to lose track of
  # among newer ones.
  def reply_overdue?
    replied_at.nil? && created_at < 1.day.ago
  end

  private

  def rate_limit
    return if ip_address.blank?

    if ShopInquiry.where(ip_address: ip_address).where("created_at > ?", GLOBAL_COOLDOWN.ago).exists?
      errors.add(:base, "送信間隔が短すぎます。しばらくしてから再度お試しください。")
    end
  end
end
