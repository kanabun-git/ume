class ShopMemberRank < ApplicationRecord
  belongs_to :shop
  has_many :shop_member_benefits, dependent: :destroy

  validates :name, presence: true
  validates :min_visit_count, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true },
    uniqueness: { scope: :shop_id }

  default_scope { order(:min_visit_count) }
end
