class ShopSubscription < ApplicationRecord
  belongs_to :shop
  belongs_to :plan

  enum :status, { active: 0, canceled: 1 }, default: :active

  validates :started_on, presence: true

  default_scope { order(started_on: :desc) }
end
