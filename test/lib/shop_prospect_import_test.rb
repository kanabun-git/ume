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
    assert ShopProspect.exists?(name: "サンプル店舗A", phone: "03-1111-1111", genre: "ソープ/吉原")
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

  test "strips a leading UTF-8 byte-order mark (as Excel adds on Windows)" do
    csv = "﻿店舗名,ジャンル,電話番号,メールアドレス,URL\nBOM付き店舗,,,,\n"

    result = ShopProspectImport.call(StringIO.new(csv))

    assert_equal 1, result.created_count
    assert ShopProspect.exists?(name: "BOM付き店舗")
  end
end
