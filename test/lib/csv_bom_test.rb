require "test_helper"
require "csv_bom"

class CsvBomTest < ActiveSupport::TestCase
  test "wrap prepends the UTF-8 byte-order mark" do
    wrapped = CsvBom.wrap("名前,スラッグ\n")

    assert_equal [0xEF, 0xBB, 0xBF], wrapped.bytes.first(3)
    assert wrapped.end_with?("名前,スラッグ\n")
  end
end
