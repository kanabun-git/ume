class CouponUsage < ApplicationRecord
  belongs_to :coupon

  enum :usage_type, { net_reservation: 0, manual: 1 }, default: :net_reservation

  default_scope { order(created_at: :desc) }
end
