class Shift < ApplicationRecord
  belongs_to :cast

  enum :status, { scheduled: 0, cancelled: 1 }, default: :scheduled

  validates :work_date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_time_after_start_time

  default_scope { order(:work_date, :start_time) }

  # Formatted "18:00 - 26:00" range. `format` is the owning shop's
  # time_display_format; passing it in lets callers that already loaded the
  # shop avoid an extra query per shift.
  def formatted_time_range(format = nil)
    "#{formatted_start_time} - #{formatted_end_time(format)}"
  end

  def formatted_start_time
    start_time.strftime("%H:%M")
  end

  # In `extended` format an overnight end time is shown as 24+ hours
  # (02:00 the next morning becomes 26:00), which is the convention this
  # industry uses. In `standard` format it stays a plain clock time.
  def formatted_end_time(format = nil)
    format ||= cast&.shop&.time_display_format
    return end_time.strftime("%H:%M") unless ends_next_day? && format.to_s == "extended"

    "#{end_time.hour + 24}:#{end_time.strftime('%M')}"
  end

  # The actual wall-clock moment the shift ends, accounting for the day
  # rollover — the ordering-safe counterpart to the raw `end_time` column.
  def ends_at
    date = ends_next_day? ? work_date + 1 : work_date
    Time.zone.local(date.year, date.month, date.day, end_time.hour, end_time.min)
  end

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    # An overnight shift legitimately ends at an earlier clock time than it
    # starts, so the ordering check only applies within the same day.
    return if ends_next_day?

    if end_time <= start_time
      errors.add(:end_time, "は開始時刻より後にしてください(日をまたぐ場合は「翌日にまたぐ」にチェックしてください)")
    end
  end
end
