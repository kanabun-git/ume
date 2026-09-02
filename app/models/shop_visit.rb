class ShopVisit < ApplicationRecord
  belongs_to :shop_membership
  belongs_to :cast, optional: true

  # `unspecified` covers both a manually-logged visit where the shop hasn't
  # decided the designation yet and a QR check-in (which only ever knows
  # the cast, not how the customer was designated) -- a shop admin fills
  # this in later via ShopVisitsController#update.
  enum :designation, { unspecified: 0, main_nomination: 1, net_nomination: 2, free: 3 }, default: :unspecified

  DESIGNATION_LABELS = {
    "unspecified" => "未設定(店舗が後で設定)",
    "main_nomination" => "本指名",
    "net_nomination" => "ネット指名",
    "free" => "フリー"
  }.freeze

  validates :visited_at, presence: true
  validates :points_earned, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :duration_minutes, numericality: { greater_than: 0, only_integer: true }, allow_nil: true

  default_scope { order(visited_at: :desc, created_at: :desc) }

  # `enum ... default:` only applies when the attribute is left untouched --
  # callers that explicitly pass `designation: nil` (record_visit! with no
  # designation given, a QR check-in, params[:designation] blank on
  # create/update) would otherwise store a real NULL instead of falling
  # back to the default.
  before_validation { self.designation ||= "unspecified" }

  def designation_label
    DESIGNATION_LABELS.fetch(designation)
  end
end
