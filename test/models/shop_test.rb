require "test_helper"

class ShopTest < ActiveSupport::TestCase
  test "in_region matches shops in a directly-regioned (prefecture) area" do
    kanto_area = create_area(region: "関東")
    chubu_area = create_area(region: "中部")
    kanto_shop = create_shop(area: kanto_area)
    chubu_shop = create_shop(area: chubu_area)

    assert_includes Shop.in_region("関東"), kanto_shop
    assert_not_includes Shop.in_region("関東"), chubu_shop
  end

  test "in_region falls back to a child area's parent prefecture region" do
    parent = create_area(region: "中部")
    child = create_area(parent: parent)
    shop = create_shop(area: child)

    assert_includes Shop.in_region("中部"), shop
    assert_not_includes Shop.in_region("関東"), shop
  end
end
