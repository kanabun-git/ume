class ShopMemberBenefit < ApplicationRecord
  belongs_to :shop_member_rank
  has_many :shop_member_benefit_grants, dependent: :destroy

  enum :benefit_type, { discount_ticket: 0, free_ticket: 1 }, default: :discount_ticket

  validates :name, presence: true
end
