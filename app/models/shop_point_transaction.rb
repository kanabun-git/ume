class ShopPointTransaction < ApplicationRecord
  belongs_to :shop_membership

  validates :amount, presence: true, numericality: { only_integer: true }
  validates :reason, presence: true

  default_scope { order(created_at: :desc) }
end
