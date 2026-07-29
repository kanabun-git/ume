require "test_helper"

class ShiftTest < ActiveSupport::TestCase
  test "standard format shows a same-day shift as plain 24h time" do
    cast = create_cast(shop: create_shop(time_display_format: :standard))
    shift = cast.shifts.create!(work_date: Date.current, start_time: "18:00", end_time: "23:00")

    assert_equal "23:00", shift.formatted_end_time
  end

  test "extended format shows an overnight shift past midnight as 24+ hours" do
    cast = create_cast(shop: create_shop(time_display_format: :extended))
    shift = cast.shifts.create!(work_date: Date.current, start_time: "20:00", end_time: "02:00", ends_next_day: true)

    assert_equal "26:00", shift.formatted_end_time
  end

  test "standard format keeps an overnight shift as plain 24h time" do
    cast = create_cast(shop: create_shop(time_display_format: :standard))
    shift = cast.shifts.create!(work_date: Date.current, start_time: "20:00", end_time: "02:00", ends_next_day: true)

    assert_equal "02:00", shift.formatted_end_time
  end

  test "ends_at lands on the following calendar day for an overnight shift" do
    cast = create_cast
    shift = cast.shifts.create!(work_date: Date.current, start_time: "20:00", end_time: "02:00", ends_next_day: true)

    assert_equal Date.current + 1, shift.ends_at.to_date
  end

  test "invalid when end time is before start time and ends_next_day is not set" do
    shift = create_cast.shifts.build(work_date: Date.current, start_time: "20:00", end_time: "18:00")

    assert_not shift.valid?
    assert_includes shift.errors[:end_time].join, "翌日にまたぐ"
  end

  test "valid when end time is before start time but ends_next_day is set" do
    shift = create_cast.shifts.build(work_date: Date.current, start_time: "20:00", end_time: "18:00", ends_next_day: true)

    assert shift.valid?
  end
end
