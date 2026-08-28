require "test_helper"
require "member_rank_import"

class MemberRankImportTest < ActiveSupport::TestCase
  test "creates a member rank per valid row" do
    csv = <<~CSV
      ランク名,必要承認件数
      ブロンズ会員,1
      シルバー会員,5
    CSV

    result = MemberRankImport.call(StringIO.new(csv))

    assert_equal 2, result.created_count
    assert_empty result.error_rows
    assert MemberRank.exists?(name: "ブロンズ会員", min_approved_count: 1)
    assert MemberRank.exists?(name: "シルバー会員", min_approved_count: 5)
  end

  test "skips a duplicate threshold and reports the line number" do
    MemberRank.create!(name: "既存ランク", min_approved_count: 3)

    csv = <<~CSV
      ランク名,必要承認件数
      重複ランク,3
      新規ランク,10
    CSV

    result = MemberRankImport.call(StringIO.new(csv))

    assert_equal 1, result.created_count
    assert_equal 1, result.error_rows.size
    assert_equal 2, result.error_rows.first[:line]
    assert MemberRank.exists?(name: "新規ランク")
    assert_not MemberRank.exists?(name: "重複ランク")
  end

  test "exports member ranks as a CSV that round-trips through the importer" do
    rank = MemberRank.create!(name: "ブロンズ会員", min_approved_count: 1)

    csv = MemberRankImport.export(MemberRank.where(id: rank.id))

    rows = CSV.parse(csv, headers: true)
    assert_equal ["ブロンズ会員", "1"], rows.first.fields
  end

  test "TEMPLATE_CSV and export both start with a UTF-8 BOM so Excel doesn't mangle the Japanese headers" do
    assert_equal [0xEF, 0xBB, 0xBF], MemberRankImport::TEMPLATE_CSV.bytes.first(3)
    assert_equal [0xEF, 0xBB, 0xBF], MemberRankImport.export(MemberRank.none).bytes.first(3)
  end
end
