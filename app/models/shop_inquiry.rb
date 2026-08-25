class ShopInquiry < ApplicationRecord
  enum :status, { pending: 0, in_progress: 1, closed: 2 }, default: :pending

  validates :shop_name, presence: true
  validates :contact_name, presence: true
  validates :email, presence: true
  validates :phone, presence: true

  default_scope { order(created_at: :desc) }

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def archived?
    archived_at.present?
  end
end
