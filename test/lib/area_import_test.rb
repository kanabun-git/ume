require "test_helper"
require "area_import"

class AreaImportTest < ActiveSupport::TestCase
  test "creates a prefecture and resolves a child's parent by slug" do
    csv = <<~CSV
      名前,カナ,スラッグ,地方,表示順,親エリアのスラッグ
      東京都,とうきょうと,tokyo,関東,1,
      新宿,しんじゅく,shinjuku,,1,tokyo
    CSV

    result = AreaImport.call(StringIO.new(csv))

    assert_equal 2, result.created_count
    assert_empty result.error_rows
    tokyo = Area.find_by(slug: "tokyo")
    shinjuku = Area.find_by(slug: "shinjuku")
    assert tokyo.present?
    assert_equal tokyo.id, shinjuku.parent_id
  end

  test "skips a prefecture-level row missing its required region and reports the line number" do
    csv = <<~CSV
      名前,カナ,スラッグ,地方,表示順,親エリアのスラッグ
      不正エリア,ふせいえりあ,invalid-area,,1,
      正常エリア,せいじょうえりあ,valid-area,関東,2,
    CSV

    result = AreaImport.call(StringIO.new(csv))

    assert_equal 1, result.created_count
    assert_equal 1, result.error_rows.size
    assert_equal 2, result.error_rows.first[:line]
    assert Area.exists?(slug: "valid-area")
    assert_not Area.exists?(slug: "invalid-area")
  end

  test "exports areas as a CSV, writing a child's parent as its slug" do
    tokyo = Area.create!(name: "東京都", slug: "tokyo", region: "関東")
    shinjuku = Area.create!(name: "新宿", slug: "shinjuku", parent: tokyo)

    csv = AreaImport.export(Area.where(id: [tokyo.id, shinjuku.id]))

    rows = CSV.parse(csv, headers: true)
    tokyo_row = rows.find { |r| r["スラッグ"] == "tokyo" }
    shinjuku_row = rows.find { |r| r["スラッグ"] == "shinjuku" }
    assert_equal "", tokyo_row["親エリアのスラッグ"].to_s
    assert_equal "tokyo", shinjuku_row["親エリアのスラッグ"]
  end

  test "TEMPLATE_CSV and export both start with a UTF-8 BOM so Excel doesn't mangle the Japanese headers" do
    assert_equal [0xEF, 0xBB, 0xBF], AreaImport::TEMPLATE_CSV.bytes.first(3)
    assert_equal [0xEF, 0xBB, 0xBF], AreaImport.export(Area.none).bytes.first(3)
  end
end
