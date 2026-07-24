class Review < ApplicationRecord
  belongs_to :shop
  belongs_to :cast, optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  validates :reviewer_name, presence: true
  validates :body, presence: true
  validates :rating, inclusion: { in: 1..5 }

  scope :visible, -> { approved }
  default_scope { order(created_at: :desc) }
end
