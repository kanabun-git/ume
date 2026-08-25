# A district (e.g. "錦糸町") pulled out of ShopProspect#genre's trailing
# "業種/地区" segment (see ShopProspect#sync_shop_prospect_district) and
# auto-registered the first time it's seen. prefecture defaults to "東京"
# since every listing exported so far only covers Tokyo -- an admin can
# correct it per district via 営業先候補管理 > 地区管理 once other
# prefectures start showing up.
class ShopProspectDistrict < ApplicationRecord
  has_many :shop_prospects

  validates :name, presence: true, uniqueness: true
  validates :prefecture, presence: true

  default_scope { order(:prefecture, :name) }

  def display_name
    "#{prefecture}ー#{name}"
  end
end
