require "test_helper"

class ShopProspectDistrictTest < ActiveSupport::TestCase
  test "requires a unique name" do
    ShopProspectDistrict.create!(name: "錦糸町")
    duplicate = ShopProspectDistrict.new(name: "錦糸町")

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :name
  end

  test "defaults prefecture to 東京" do
    district = ShopProspectDistrict.create!(name: "錦糸町")

    assert_equal "東京", district.prefecture
  end

  test "display_name joins prefecture and name with ー" do
    district = ShopProspectDistrict.new(prefecture: "東京", name: "錦糸町")

    assert_equal "東京ー錦糸町", district.display_name
  end

  test "fix_known_prefectures! corrects a district that was mis-defaulted to 東京" do
    funabashi = ShopProspectDistrict.create!(name: "船橋") # defaults to 東京, but it's in 千葉

    corrected = ShopProspectDistrict.fix_known_prefectures!

    assert_equal [["船橋", "東京", "千葉"]], corrected
    assert_equal "千葉", funabashi.reload.prefecture
  end

  test "fix_known_prefectures! does not touch a district that's already correct, or one outside the known list" do
    ShopProspectDistrict.create!(name: "錦糸町") # correctly 東京, not in the correction list

    corrected = ShopProspectDistrict.fix_known_prefectures!

    assert_empty corrected
    assert_equal "東京", ShopProspectDistrict.find_by(name: "錦糸町").prefecture
  end

  test "fix_known_prefectures! is safe to run twice" do
    ShopProspectDistrict.create!(name: "船橋")

    ShopProspectDistrict.fix_known_prefectures!
    second_run = ShopProspectDistrict.fix_known_prefectures!

    assert_empty second_run
  end

  test "fix_known_prefectures! corrects 中部ポータル districts mis-defaulted to 東京" do
    nagano = ShopProspectDistrict.create!(name: "長野市")
    kanazuen = ShopProspectDistrict.create!(name: "金津園")

    ShopProspectDistrict.fix_known_prefectures!

    assert_equal "長野", nagano.reload.prefecture
    assert_equal "岐阜", kanazuen.reload.prefecture
  end
end
