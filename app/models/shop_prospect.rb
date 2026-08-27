# A shop listed on a competing portal site, tracked as a sales lead for
# outreach — distinct from Shop, which represents a shop actually using
# this platform. Populated manually or via CSV import (see
# Admin::ShopProspectsController#import), never by automated scraping.
class ShopProspect < ApplicationRecord
  belongs_to :shop_prospect_district, optional: true
  has_many :shop_inquiries, dependent: :nullify

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
  # ShopProspectImport). Splits it: the 地区 half becomes a
  # ShopProspectDistrict (registering a new one automatically the first
  # time a given district name is seen), and genre itself is trimmed back
  # down to just the 業種 half, so the same place name doesn't show twice
  # (once in ジャンル, once in 地区) once it has its own column.
  before_save :sync_shop_prospect_district

  default_scope { order(created_at: :desc) }

  # One-off catch-up for prospects saved (or backfilled by an earlier
  # version of this method) before genre had its 地区 suffix split off.
  # Every row whose genre still contains "/" gets its district set
  # (registering a new one if needed) and genre trimmed to just 業種.
  # Idempotent -- a row with no "/" left in genre is skipped on later
  # runs. Never deletes or otherwise touches any other column. Safe to
  # re-run (see lib/tasks/shop_prospects.rake).
  def self.backfill_districts!
    count = 0

    where("genre LIKE ?", "%/%").find_each do |prospect|
      parts = prospect.send(:split_genre)
      next unless parts

      business_type, district_name = parts
      district = ShopProspectDistrict.find_or_create_by!(name: district_name)
      prospect.update_columns(shop_prospect_district_id: district.id, genre: business_type)
      count += 1
    end

    count
  end

  # One-off catch-up for prospects that were emailed before
  # Admin::ShopProspectsController#send_outreach_emails started advancing
  # status on send -- anything with a recorded send time is, at minimum,
  # アプローチ済み. Only touches rows still stuck at 未アプローチ; never
  # moves one already further along (negotiating/won/lost), and never
  # deletes or otherwise touches any other column. Safe to re-run.
  def self.backfill_contacted_status!
    where(status: :not_contacted).where.not(outreach_email_sent_at: nil)
      .update_all(status: statuses[:contacted])
  end

  private

  def sync_shop_prospect_district
    return unless genre_changed?

    parts = split_genre
    return unless parts

    business_type, district_name = parts
    self.shop_prospect_district = ShopProspectDistrict.find_or_create_by!(name: district_name)
    self.genre = business_type
  end

  # Splits genre's "業種/地区" format (e.g. "デリヘル/錦糸町" -- see
  # ShopProspectImport) into [business_type, district_name], or nil if
  # genre has no usable "/" segment.
  def split_genre
    return if genre.blank? || !genre.include?("/")

    business_type, district_name = genre.split("/", 2).map { |part| part.to_s.strip }
    return if district_name.blank?

    [business_type, district_name]
  end
end
