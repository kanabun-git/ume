require "test_helper"
require "shop_prospect_import"

class ShopProspectImportTest < ActiveSupport::TestCase
  test "creates a prospect per valid row" do
    csv = <<~CSV
      店舗名,ジャンル,電話番号,メールアドレス,URL
      サンプル店舗A,ソープ/吉原,03-1111-1111,a@example.com,https://example.com/a
      サンプル店舗B,デリヘル/上野,03-2222-2222,b@example.com,https://example.com/b
    CSV

    result = ShopProspectImport.call(StringIO.new(csv))

    assert_equal 2, result.created_count
    assert_empty result.error_rows
    assert ShopProspect.exists?(name: "サンプル店舗A", phone: "03-1111-1111", genre: "ソープ")
    assert_equal "吉原", ShopProspect.find_by(name: "サンプル店舗A").shop_prospect_district.name
    assert ShopProspect.exists?(name: "サンプル店舗B", listing_url: "https://example.com/b")
  end

  test "skips rows missing a required field and reports the line number" do
    csv = <<~CSV
      店舗名,ジャンル,電話番号,メールアドレス,URL
      ,ソープ/吉原,03-1111-1111,a@example.com,https://example.com/a
      サンプル店舗C,ソープ/吉原,03-3333-3333,c@example.com,https://example.com/c
    CSV

    result = ShopProspectImport.call(StringIO.new(csv))

    assert_equal 1, result.created_count
    assert_equal 1, result.error_rows.size
    assert_equal 2, result.error_rows.first[:line]
    assert ShopProspect.exists?(name: "サンプル店舗C")
  end

  test "skips area-header rows like 【吉原】 instead of importing them as prospects" do
    csv = <<~CSV
      店舗名,ジャンル,電話番号,メールアドレス,URL
      【吉原】,,,,
      サンプル店舗D,ソープ/吉原,03-4444-4444,d@example.com,https://example.com/d
      【上野】,,,,
    CSV

    result = ShopProspectImport.call(StringIO.new(csv))

    assert_equal 1, result.created_count
    assert_empty result.error_rows
    assert ShopProspect.exists?(name: "サンプル店舗D")
    assert_not ShopProspect.exists?(name: "【吉原】")
    assert_not ShopProspect.exists?(name: "【上野】")
  end

  test "imported rows auto-register their district from genre" do
    csv = <<~CSV
      店舗名,ジャンル,電話番号,メールアドレス,URL
      サンプル店舗A,ソープ/吉原,03-1111-1111,a@example.com,https://example.com/a
      サンプル店舗B,デリヘル/吉原,03-2222-2222,b@example.com,https://example.com/b
    CSV

    ShopProspectImport.call(StringIO.new(csv))

    assert_equal 1, ShopProspectDistrict.count
    district = ShopProspectDistrict.find_by(name: "吉原")
    assert_equal 2, district.shop_prospects.count
  end

  test "strips a leading UTF-8 byte-order mark (as Excel adds on Windows)" do
    csv = "﻿店舗名,ジャンル,電話番号,メールアドレス,URL\nBOM付き店舗,,,,\n"

    result = ShopProspectImport.call(StringIO.new(csv))

    assert_equal 1, result.created_count
    assert ShopProspect.exists?(name: "BOM付き店舗")
  end

  test "TEMPLATE_CSV and export both start with a UTF-8 BOM so Excel doesn't mangle the Japanese headers" do
    assert_equal [0xEF, 0xBB, 0xBF], ShopProspectImport::TEMPLATE_CSV.bytes.first(3)
    assert_equal [0xEF, 0xBB, 0xBF], ShopProspectImport.export(ShopProspect.none).bytes.first(3)
  end
end
