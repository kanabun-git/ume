require "test_helper"

module Vintage
  class ResultTest < ActiveSupport::TestCase
    test "keeps only usable values out of a partly malformed answer" do
      result = Vintage::Result.from_text({
        item_type: "  スウェット  ",
        brand_candidates: [
          { name: "Champion", confidence: "high", reason: "トリコタグ" },
          { confidence: "low" },            # 名前が無い候補は落とす
          "Levi's",                          # 文字列だけの候補も落とす
          { name: "  ", confidence: "low" }  # 空白だけの名前も落とす
        ],
        era: nil,
        clues: ["シングルステッチ", "", nil, 42],
        summary: "要約"
      }.to_json)

      assert_equal "スウェット", result.item_type
      assert_equal ["Champion"], result.brand_candidates.map(&:name)
      assert_nil result.era
      assert_equal ["シングルステッチ"], result.clues
      assert_empty result.next_checks
    end

    test "an answer with nothing in it is reported as empty rather than as a blank page" do
      result = Vintage::Result.from_text({ brand_candidates: [] }.to_json)

      assert result.empty?
    end

    test "an unknown confidence value still renders a label" do
      result = Vintage::Result.from_text(
        { brand_candidates: [{ name: "Nike", confidence: "とても高い" }] }.to_json
      )

      assert_equal "不明", result.brand_candidates.first.confidence_label
    end

    test "brand candidates link to the guide even when the name carries a Japanese reading" do
      result = Vintage::Result.from_text(
        { brand_candidates: [{ name: "THE NORTH FACE(ザ・ノース・フェイス)", confidence: "medium" }] }.to_json
      )

      assert_equal "the-north-face", result.brand_candidates.first.guide_slug
    end

    test "a non-JSON answer raises rather than half-rendering" do
      assert_raises(Vintage::Result::ParseError) { Vintage::Result.from_text("判定できませんでした") }
      assert_raises(Vintage::Result::ParseError) { Vintage::Result.from_text("") }
      assert_raises(Vintage::Result::ParseError) { Vintage::Result.from_text("[1, 2, 3]") }
    end
  end
end
