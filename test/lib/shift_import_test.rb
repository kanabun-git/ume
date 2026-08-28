require "test_helper"
require "shift_import"

class ShiftImportTest < ActiveSupport::TestCase
  test "creates a shift per valid row, matching the cast by name within the given shop" do
    shop = create_shop
    cast = create_cast(shop: shop, name: "ゆい")

    csv = <<~CSV
      キャスト名,勤務日,開始時刻,終了時刻,翌日にまたぐ,メモ
      ゆい,2026-08-10,18:00,02:00,true,体験入店
    CSV

    result = ShiftImport.call(StringIO.new(csv), shop: shop)

    assert_equal 1, result.created_count
    assert_empty result.error_rows
    shift = cast.shifts.first
    assert_equal Date.new(2026, 8, 10), shift.work_date
    assert shift.ends_next_day?
    assert_equal "体験入店", shift.note
  end

  test "reports a row naming a cast that isn't in this shop" do
    shop = create_shop
    other_shop_cast = create_cast(name: "他店キャスト")

    csv = <<~CSV
      キャスト名,勤務日,開始時刻,終了時刻,翌日にまたぐ,メモ
      他店キャスト,2026-08-10,18:00,23:00,false,
    CSV

    result = ShiftImport.call(StringIO.new(csv), shop: shop)

    assert_equal 0, result.created_count
    assert_equal 1, result.error_rows.size
    assert_match(/他店キャスト/, result.error_rows.first[:errors])
    assert_equal 0, other_shop_cast.shifts.count
  end

  test "strips a leading UTF-8 byte-order mark (as Excel adds on Windows)" do
    shop = create_shop
    create_cast(shop: shop, name: "ゆい")
    csv = "﻿キャスト名,勤務日,開始時刻,終了時刻,翌日にまたぐ,メモ\nゆい,2026-08-10,18:00,23:00,false,\n"

    result = ShiftImport.call(StringIO.new(csv), shop: shop)

    assert_equal 1, result.created_count
  end

  test "TEMPLATE_CSV starts with a UTF-8 BOM so Excel doesn't mangle the Japanese headers" do
    assert_equal [0xEF, 0xBB, 0xBF], ShiftImport::TEMPLATE_CSV.bytes.first(3)
  end
end
