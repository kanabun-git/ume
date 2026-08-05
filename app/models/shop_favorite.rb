class ShopFavorite < ApplicationRecord
  belongs_to :member
  belongs_to :shop

  validates :shop_id, uniqueness: { scope: :member_id }
end
