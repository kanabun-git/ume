require "test_helper"
require "genre_import"

class GenreImportTest < ActiveSupport::TestCase
  test "creates a genre per valid row" do
    csv = <<~CSV
      名前,スラッグ,表示順
      ソープ,soap,1
      ヘルス,health,2
    CSV

    result = GenreImport.call(StringIO.new(csv))

    assert_equal 2, result.created_count
    assert_empty result.error_rows
    assert Genre.exists?(name: "ソープ", slug: "soap")
    assert Genre.exists?(name: "ヘルス", slug: "health")
  end

  test "skips rows with an invalid slug and reports the line number" do
    csv = <<~CSV
      名前,スラッグ,表示順
      不正ジャンル,日本語スラッグ,1
      正常ジャンル,valid-slug,2
    CSV

    result = GenreImport.call(StringIO.new(csv))

    assert_equal 1, result.created_count
    assert_equal 1, result.error_rows.size
    assert_equal 2, result.error_rows.first[:line]
    assert Genre.exists?(name: "正常ジャンル")
    assert_not Genre.exists?(name: "不正ジャンル")
  end
end
