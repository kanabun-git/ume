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

  test "#region reads directly from a prefecture-level area" do
    shop = create_shop(area: create_area(region: "関東"))

    assert_equal "関東", shop.region
  end

  test "#region falls back to a child area's parent prefecture region" do
    parent = create_area(region: "中部")
    shop = create_shop(area: create_area(parent: parent))

    assert_equal "中部", shop.region
  end

  test "#pr_badge_active? is true only while pr_badge_until is in the future" do
    assert_not create_shop(pr_badge_until: nil).pr_badge_active?
    assert_not create_shop(pr_badge_until: 1.day.ago).pr_badge_active?
    assert create_shop(pr_badge_until: 1.day.from_now).pr_badge_active?
  end
end
