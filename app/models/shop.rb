class Shop < ApplicationRecord
  belongs_to :area
  belongs_to :genre
  belongs_to :plan
  has_many :users, dependent: :nullify
  has_many :casts, dependent: :destroy
  has_many :diary_entries, through: :casts
  has_many :reviews, dependent: :destroy
  has_many :shop_subscriptions, dependent: :destroy
  has_many_attached :photos

  enum :status, { pending: 0, approved: 1, suspended: 2 }, default: :pending

  validates :name, presence: true

  scope :visible, -> { approved }
  scope :ranked, -> { visible.joins(:plan).order(Arel.sql("plans.priority_weight * shops.view_count DESC")) }

  def approved_reviews
    reviews.approved
  end

  def average_rating
    approved_reviews.average(:rating)&.round(1)
  end
end
