class ShopDailyView < ApplicationRecord
  belongs_to :shop

  validates :view_date, presence: true, uniqueness: { scope: :shop_id }

  def self.record!(shop)
    daily = find_or_create_by!(shop: shop, view_date: Date.current)
    daily.increment!(:views_count)
    daily
  end
end
