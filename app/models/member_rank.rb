class MemberRank < ApplicationRecord
  validates :name, presence: true
  validates :min_approved_count, presence: true, numericality: { greater_than_or_equal_to: 0 }, uniqueness: true

  default_scope { order(:min_approved_count) }

  # The highest-threshold rank a member with `approved_count` approved
  # reviews qualifies for, or nil if no rank's threshold is low enough
  # (e.g. no ranks configured yet, or the lowest one requires 1+).
  def self.for_approved_count(approved_count)
    where("min_approved_count <= ?", approved_count).reorder(min_approved_count: :desc).first
  end
end
