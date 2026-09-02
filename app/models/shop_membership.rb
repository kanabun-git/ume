class ShopMembership < ApplicationRecord
  belongs_to :shop
  belongs_to :member
  has_many :shop_visits, dependent: :destroy
  has_many :shop_point_transactions, dependent: :destroy
  has_many :shop_member_benefit_grants, dependent: :destroy

  before_validation :assign_member_number, on: :create

  validates :member_id, uniqueness: { scope: :shop_id }
  validates :member_number, presence: true, uniqueness: { scope: :shop_id }

  # e.g. "No.0007", for display on the member card and its printed/shared
  # form -- padded so numbers stay visually aligned as a shop's roster grows
  # past four digits.
  def formatted_member_number
    "No.#{member_number.to_s.rjust(4, "0")}"
  end

  # Visit count and point balance are derived from their log tables rather
  # than cached columns, so they can never drift out of sync with the
  # underlying history the member/shop actually see.
  def visit_count
    shop_visits.count
  end

  def points
    shop_point_transactions.sum(:amount)
  end

  def current_rank
    shop.shop_member_ranks.where("min_visit_count <= ?", visit_count).reorder(min_visit_count: :desc).first
  end

  def next_rank
    shop.shop_member_ranks.where("min_visit_count > ?", visit_count).reorder(:min_visit_count).first
  end

  # Logs a visit, awards its points (if any), and issues any benefits tied
  # to a rank this visit newly reaches. `cast`/`designation`/`duration_minutes`
  # are all optional -- a QR check-in (see CastCheckInsController) only ever
  # knows `cast`, leaving designation/duration for a shop admin to fill in
  # later via ShopVisitsController#update.
  def record_visit!(visited_at:, points_earned: 0, memo: nil, cast: nil, designation: nil, duration_minutes: nil, checked_in_by_qr: false)
    visit = nil
    transaction do
      visit = shop_visits.create!(
        visited_at: visited_at, points_earned: points_earned, memo: memo,
        cast: cast, designation: designation, duration_minutes: duration_minutes,
        checked_in_by_qr: checked_in_by_qr
      )
      shop_point_transactions.create!(amount: points_earned, reason: "来店ポイント") if points_earned.positive?
      grant_benefits_for_newly_reached_rank!
    end
    visit
  end

  # Deducts points for a redemption (a used point-benefit, a discount
  # applied at checkout, etc). Returns false without changing anything if
  # the balance is insufficient, so the caller can show an error instead
  # of ever letting the balance go negative.
  def redeem_points!(amount, reason:)
    return false if amount <= 0 || amount > points

    shop_point_transactions.create!(amount: -amount, reason: reason)
    true
  end

  private

  def assign_member_number
    return if member_number.present? || shop.blank?

    self.member_number = shop.shop_memberships.maximum(:member_number).to_i + 1
  end

  def grant_benefits_for_newly_reached_rank!
    rank = shop.shop_member_ranks.find_by(min_visit_count: visit_count)
    return if rank.blank?

    rank.shop_member_benefits.find_each do |benefit|
      shop_member_benefit_grants.create!(shop_member_benefit: benefit)
    end
  end
end
