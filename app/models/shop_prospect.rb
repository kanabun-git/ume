# A shop listed on a competing portal site, tracked as a sales lead for
# outreach — distinct from Shop, which represents a shop actually using
# this platform. Populated manually or via CSV import (see
# Admin::ShopProspectsController#import), never by automated scraping.
class ShopProspect < ApplicationRecord
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

  default_scope { order(created_at: :desc) }
end
