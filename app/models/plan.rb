class Plan < ApplicationRecord
  has_many :shops, dependent: :restrict_with_error
  has_many :shop_subscriptions, dependent: :restrict_with_error

  validates :name, presence: true
  validates :monthly_fee, numericality: { greater_than_or_equal_to: 0 }
  validates :priority_weight, numericality: { greater_than: 0 }

  default_scope { order(:position, :name) }
end
