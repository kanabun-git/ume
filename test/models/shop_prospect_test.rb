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
end
