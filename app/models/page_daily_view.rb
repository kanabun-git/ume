# Daily view counter for named top-level pages that aren't backed by a
# Shop/Cast record (see ShopDailyView/CastDailyView for those) -- the
# age-gate TOP page and the region portals it leads into. Viewable only by
# platform admins via Admin::AnalyticsController.
class PageDailyView < ApplicationRecord
  PAGE_KEYS = {
    "index" => "INDEXページ",
    "kanto" => "関東ポータル",
    "chubu" => "中部ポータル"
  }.freeze

  validates :page_key, presence: true, inclusion: { in: PAGE_KEYS.keys }
  validates :view_date, presence: true, uniqueness: { scope: :page_key }

  def self.record!(page_key)
    daily = find_or_create_by!(page_key: page_key, view_date: Date.current)
    daily.increment!(:views_count)
    daily
  end

  def self.label_for(page_key)
    PAGE_KEYS.fetch(page_key, page_key)
  end
end
