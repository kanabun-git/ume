class Coupon < ApplicationRecord
  belongs_to :shop

  validates :title, presence: true
  validates :course_name, presence: true
  validates :regular_price, numericality: { greater_than: 0, only_integer: true }
  validates :discounted_price, numericality: { greater_than: 0, only_integer: true }
  validates :valid_from, presence: true
  validate :discounted_price_below_regular_price
  validate :valid_until_after_valid_from

  scope :active, -> {
    where("valid_from <= ?", Date.current).where("valid_until IS NULL OR valid_until >= ?", Date.current)
  }

  default_scope { order(:position, created_at: :desc) }

  def discount_percent
    return 0 if regular_price.zero?

    (100 - (discounted_price * 100.0 / regular_price)).round
  end

  def unlimited?
    valid_until.blank?
  end

  private

  def discounted_price_below_regular_price
    return if regular_price.blank? || discounted_price.blank?

    errors.add(:discounted_price, "は通常料金より低い金額にしてください") if discounted_price >= regular_price
  end

  def valid_until_after_valid_from
    return if valid_from.blank? || valid_until.blank?

    errors.add(:valid_until, "は開始日より後にしてください") if valid_until < valid_from
  end
end
