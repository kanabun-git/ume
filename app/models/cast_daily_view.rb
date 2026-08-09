class CastDailyView < ApplicationRecord
  belongs_to :cast

  validates :view_date, presence: true, uniqueness: { scope: :cast_id }

  def self.record!(cast)
    daily = find_or_create_by!(cast: cast, view_date: Date.current)
    daily.increment!(:views_count)
    daily
  end
end
