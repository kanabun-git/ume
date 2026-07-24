class Shift < ApplicationRecord
  belongs_to :cast

  enum :status, { scheduled: 0, cancelled: 1 }, default: :scheduled

  validates :work_date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_time_after_start_time

  default_scope { order(:work_date, :start_time) }

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?

    errors.add(:end_time, "は開始時刻より後にしてください") if end_time <= start_time
  end
end
