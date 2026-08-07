class ShopMemberBenefitGrant < ApplicationRecord
  belongs_to :shop_membership
  belongs_to :shop_member_benefit

  enum :status, { unused: 0, used: 1 }, default: :unused

  default_scope { order(created_at: :desc) }

  def mark_used!
    update!(status: :used, used_at: Time.current)
  end
end
