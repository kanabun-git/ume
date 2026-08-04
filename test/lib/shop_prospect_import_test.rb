require "test_helper"
require "shop_prospect_import"

class ShopProspectImportTest < ActiveSupport::TestCase
  test "creates a prospect per valid row" do
    csv = <<~CSV
      店舗名,電話番号,メールアドレス,掲載サイト名,掲載URL,メモ
      サンプル店舗A,03-1111-1111,a@example.com,○○ネット,https://example.com/a,担当:田中様
      サンプル店舗B,03-2222-2222,b@example.com,△△ネット,https://example.com/b,
    CSV

    result = ShopProspectImport.call(StringIO.new(csv))

    assert_equal 2, result.created_count
    assert_empty result.error_rows
    assert ShopProspect.exists?(name: "サンプル店舗A", phone: "03-1111-1111")
    assert ShopProspect.exists?(name: "サンプル店舗B")
  end

  test "skips rows missing a required field and reports the line number" do
    csv = <<~CSV
      店舗名,電話番号,メールアドレス,掲載サイト名,掲載URL,メモ
      ,03-1111-1111,a@example.com,○○ネット,https://example.com/a,
      サンプル店舗C,03-3333-3333,c@example.com,○○ネット,https://example.com/c,
    CSV

    result = ShopProspectImport.call(StringIO.new(csv))

    assert_equal 1, result.created_count
    assert_equal 1, result.error_rows.size
    assert_equal 2, result.error_rows.first[:line]
    assert ShopProspect.exists?(name: "サンプル店舗C")
  end

  test "strips a leading UTF-8 byte-order mark (as Excel adds on Windows)" do
    csv = "﻿店舗名,電話番号,メールアドレス,掲載サイト名,掲載URL,メモ\nBOM付き店舗,,,,,\n"

    result = ShopProspectImport.call(StringIO.new(csv))

    assert_equal 1, result.created_count
    assert ShopProspect.exists?(name: "BOM付き店舗")
  end
end
