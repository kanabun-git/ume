class ShopVisit < ApplicationRecord
  belongs_to :shop_membership

  validates :visited_on, presence: true
  validates :points_earned, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  default_scope { order(visited_on: :desc, created_at: :desc) }
end
