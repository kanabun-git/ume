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
end
