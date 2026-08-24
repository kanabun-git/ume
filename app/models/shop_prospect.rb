# A shop listed on a competing portal site, tracked as a sales lead for
# outreach — distinct from Shop, which represents a shop actually using
# this platform. Populated manually or via CSV import (see
# Admin::ShopProspectsController#import), never by automated scraping.
class ShopProspect < ApplicationRecord
  belongs_to :shop_prospect_district, optional: true

  enum :status, {
    not_contacted: 0,
    contacted: 1,
    negotiating: 2,
    won: 3,
    lost: 4
  }, default: :not_contacted

  validates :name, presence: true

  # Every prospect gets a click-tracking token up front (not lazily at send
  # time) so the outreach link stays the same even if a lead is re-emailed.
  before_create { self.outreach_token ||= SecureRandom.hex(16) }

  # genre arrives as "業種/地区" (e.g. "デリヘル/錦糸町" -- see
  # ShopProspectImport). Pulls out the 地区 half and links it to a
  # ShopProspectDistrict, registering a new one automatically the first
  # time a given district name is seen, so 営業先候補管理 can group/filter
  # the list by district instead of showing every row flat.
  before_save :sync_shop_prospect_district

  default_scope { order(created_at: :desc) }

  private

  def sync_shop_prospect_district
    return unless genre_changed?
    return if genre.blank? || !genre.include?("/")

    district_name = genre.split("/", 2).last.to_s.strip
    return if district_name.blank?

    self.shop_prospect_district = ShopProspectDistrict.find_or_create_by!(name: district_name)
  end
end
