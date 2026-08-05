require "test_helper"
require "shift_bulk_create"

class ShiftBulkCreateTest < ActiveSupport::TestCase
  test "creates a shift on every date within range that falls on a selected weekday" do
    cast = create_cast
    # 2026-08-10 is a Monday, 2026-08-16 is a Sunday: one full week.
    result = ShiftBulkCreate.call(
      cast: cast,
      start_date: Date.new(2026, 8, 10),
      end_date: Date.new(2026, 8, 16),
      weekdays: [1, 3, 5], # Mon/Wed/Fri
      start_time: "18:00",
      end_time: "02:00",
      ends_next_day: true,
      note: "テスト"
    )

    assert_equal 3, result.created_count
    assert_empty result.error_rows
    assert_equal [Date.new(2026, 8, 10), Date.new(2026, 8, 12), Date.new(2026, 8, 14)], cast.shifts.pluck(:work_date).sort
  end

  test "reports a row that fails validation without stopping the rest" do
    cast = create_cast

    result = ShiftBulkCreate.call(
      cast: cast,
      start_date: Date.new(2026, 8, 10),
      end_date: Date.new(2026, 8, 11),
      weekdays: [0, 1, 2, 3, 4, 5, 6],
      start_time: "18:00",
      end_time: "10:00",
      ends_next_day: false,
      note: nil
    )

    assert_equal 0, result.created_count
    assert_equal 2, result.error_rows.size
  end
end
