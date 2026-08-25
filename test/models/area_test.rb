require "test_helper"

class AreaTest < ActiveSupport::TestCase
  test ".region_for_prefecture_name resolves a bare prefecture name" do
    assert_equal "関東", Area.region_for_prefecture_name("東京")
    assert_equal "関西", Area.region_for_prefecture_name("大阪")
    assert_equal "北海道", Area.region_for_prefecture_name("北海道")
  end

  test ".region_for_prefecture_name also resolves a name with the 都/道/府/県 suffix" do
    assert_equal "関東", Area.region_for_prefecture_name("東京都")
    assert_equal "関西", Area.region_for_prefecture_name("大阪府")
    assert_equal "関東", Area.region_for_prefecture_name("神奈川県")
  end

  test ".region_for_prefecture_name returns nil for an unrecognized name" do
    assert_nil Area.region_for_prefecture_name("架空の県")
  end

  test ".generate_unique_slug returns a slug that passes Area's own format validation and is not already taken" do
    existing = Area.create!(name: "既存エリア", slug: Area.generate_unique_slug, region: "関東")

    slug = Area.generate_unique_slug

    assert_match(/\A[a-z0-9\-]+\z/, slug)
    assert_not_equal existing.slug, slug
    assert_not Area.exists?(slug: slug)
  end
end
