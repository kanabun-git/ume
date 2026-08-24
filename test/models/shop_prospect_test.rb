require "test_helper"

class ShopProspectTest < ActiveSupport::TestCase
  test "requires a name" do
    prospect = ShopProspect.new

    assert_not prospect.valid?
    assert_includes prospect.errors.attribute_names, :name
  end

  test "defaults to not_contacted status" do
    prospect = ShopProspect.create!(name: "テスト候補店舗")

    assert prospect.not_contacted?
  end

  test "assigns a unique outreach_token on create" do
    a = ShopProspect.create!(name: "候補A")
    b = ShopProspect.create!(name: "候補B")

    assert a.outreach_token.present?
    assert_not_equal a.outreach_token, b.outreach_token
  end

  test "genre with a 業種/地区 slash auto-registers the district" do
    prospect = ShopProspect.create!(name: "候補店舗", genre: "デリヘル/錦糸町")

    assert_equal "錦糸町", prospect.shop_prospect_district.name
    assert_equal "東京", prospect.shop_prospect_district.prefecture
  end

  test "two prospects with the same district share one ShopProspectDistrict row" do
    a = ShopProspect.create!(name: "候補A", genre: "デリヘル/錦糸町")
    b = ShopProspect.create!(name: "候補B", genre: "ソープ/錦糸町")

    assert_equal a.shop_prospect_district_id, b.shop_prospect_district_id
    assert_equal 1, ShopProspectDistrict.count
  end

  test "genre without a slash leaves the district unset" do
    prospect = ShopProspect.create!(name: "候補店舗", genre: "デリヘル")

    assert_nil prospect.shop_prospect_district
  end

  test "blank genre leaves the district unset" do
    prospect = ShopProspect.create!(name: "候補店舗")

    assert_nil prospect.shop_prospect_district
  end

  test "editing genre to a new district re-syncs it" do
    prospect = ShopProspect.create!(name: "候補店舗", genre: "デリヘル/錦糸町")

    prospect.update!(genre: "デリヘル/浅草")

    assert_equal "浅草", prospect.shop_prospect_district.name
  end

  test "backfill_districts! fills in the district for pre-existing rows without touching anything else" do
    prospect = ShopProspect.create!(name: "候補店舗", genre: "デリヘル/錦糸町")
    prospect.update_column(:shop_prospect_district_id, nil) # simulate a row saved before this feature existed

    count = ShopProspect.backfill_districts!

    assert_equal 1, count
    assert_equal "錦糸町", prospect.reload.shop_prospect_district.name
    assert ShopProspect.exists?(prospect.id)
  end

  test "backfill_districts! does not touch prospects without a usable genre" do
    ShopProspect.create!(name: "地区なし候補", genre: "デリヘル")

    count = ShopProspect.backfill_districts!

    assert_equal 0, count
    assert ShopProspect.exists?(name: "地区なし候補")
  end

  test "backfill_districts! is safe to run twice" do
    prospect = ShopProspect.create!(name: "候補店舗", genre: "デリヘル/錦糸町")
    prospect.update_column(:shop_prospect_district_id, nil)

    ShopProspect.backfill_districts!
    second_run_count = ShopProspect.backfill_districts!

    assert_equal 0, second_run_count
  end
end
