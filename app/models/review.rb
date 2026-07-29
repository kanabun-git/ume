class Review < ApplicationRecord
  # Anonymous, unauthenticated posting is a spam target; these two rate
  # limits (checked in `rate_limit`, on: :create only — see below) are a
  # lightweight defense that doesn't require an external CAPTCHA service.
  SAME_SHOP_COOLDOWN = 24.hours
  GLOBAL_COOLDOWN = 1.minute

  belongs_to :shop
  belongs_to :cast, optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  validates :reviewer_name, presence: true
  validates :body, presence: true
  validates :rating, inclusion: { in: 1..5 }
  validate :rate_limit, on: :create

  scope :visible, -> { approved }
  default_scope { order(created_at: :desc) }

  private

  def rate_limit
    return if ip_address.blank?

    if Review.where(shop_id: shop_id, ip_address: ip_address).where("created_at > ?", SAME_SHOP_COOLDOWN.ago).exists?
      errors.add(:base, "同じ店舗への口コミ投稿は24時間に1件までです。")
    elsif Review.where(ip_address: ip_address).where("created_at > ?", GLOBAL_COOLDOWN.ago).exists?
      errors.add(:base, "投稿の間隔が短すぎます。しばらくしてから再度お試しください。")
    end
  end
end
