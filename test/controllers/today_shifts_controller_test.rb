require "test_helper"

class TodayShiftsControllerTest < ActionDispatch::IntegrationTest
  test "lists casts scheduled to work today, excluding other days and cancelled shifts" do
    shop = create_shop
    today_cast = create_cast(shop: shop, name: "本日出勤キャスト")
    tomorrow_cast = create_cast(shop: shop, name: "翌日出勤キャスト")
    cancelled_cast = create_cast(shop: shop, name: "キャンセルキャスト")
    today_cast.shifts.create!(work_date: Date.current, start_time: "18:00", end_time: "23:00")
    tomorrow_cast.shifts.create!(work_date: Date.current + 1, start_time: "18:00", end_time: "23:00")
    cancelled_cast.shifts.create!(work_date: Date.current, start_time: "12:00", end_time: "17:00", status: :cancelled)

    get today_shifts_path

    assert_response :success
    assert_match today_cast.name, response.body
    assert_no_match tomorrow_cast.name, response.body
    assert_no_match cancelled_cast.name, response.body
  end

  test "excludes shifts from inactive casts and unapproved shops" do
    inactive_cast = create_cast(status: :inactive, name: "退店キャスト")
    inactive_cast.shifts.create!(work_date: Date.current, start_time: "18:00", end_time: "23:00")

    suspended_shop = create_shop(status: :suspended)
    suspended_cast = create_cast(shop: suspended_shop, name: "停止店キャスト")
    suspended_cast.shifts.create!(work_date: Date.current, start_time: "18:00", end_time: "23:00")

    get today_shifts_path

    assert_response :success
    assert_no_match inactive_cast.name, response.body
    assert_no_match suspended_cast.name, response.body
  end

  test "filters by area_id" do
    matching_area = create_area
    other_area = create_area
    matching_cast = create_cast(shop: create_shop(area: matching_area), name: "対象エリアキャスト")
    other_cast = create_cast(shop: create_shop(area: other_area), name: "対象外エリアキャスト")
    matching_cast.shifts.create!(work_date: Date.current, start_time: "18:00", end_time: "23:00")
    other_cast.shifts.create!(work_date: Date.current, start_time: "18:00", end_time: "23:00")

    get today_shifts_path, params: { area_id: matching_area.id }

    assert_response :success
    assert_match matching_cast.name, response.body
    assert_no_match other_cast.name, response.body
  end
end
