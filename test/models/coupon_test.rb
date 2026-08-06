require "test_helper"

class CouponTest < ActiveSupport::TestCase
  test "#discount_percent rounds the percentage off the regular price" do
    coupon = Coupon.new(regular_price: 20000, discounted_price: 14000)

    assert_equal 30, coupon.discount_percent
  end

  test "#unlimited? is true when valid_until is blank" do
    assert Coupon.new(valid_until: nil).unlimited?
    assert_not Coupon.new(valid_until: Date.tomorrow).unlimited?
  end

  test "rejects a discounted_price that isn't below the regular price" do
    coupon = build_coupon(regular_price: 10000, discounted_price: 10000)

    assert_not coupon.valid?
    assert_includes coupon.errors.attribute_names, :discounted_price
  end

  test "rejects a valid_until before valid_from" do
    coupon = build_coupon(valid_from: Date.current, valid_until: 1.day.ago.to_date)

    assert_not coupon.valid?
    assert_includes coupon.errors.attribute_names, :valid_until
  end

  test ".active excludes a coupon that hasn't started yet" do
    coupon = create_coupon(valid_from: 1.day.from_now.to_date)

    assert_not_includes Coupon.active, coupon
  end

  test ".active excludes a coupon whose valid_until has passed" do
    coupon = create_coupon(valid_from: 10.days.ago.to_date, valid_until: 1.day.ago.to_date)

    assert_not_includes Coupon.active, coupon
  end

  test ".active includes a currently-running unlimited coupon" do
    coupon = create_coupon(valid_from: 1.day.ago.to_date, valid_until: nil)

    assert_includes Coupon.active, coupon
  end

  private

  def build_coupon(**attrs)
    create_shop.coupons.build({
      title: "テストクーポン", course_name: "60分コース",
      regular_price: 20000, discounted_price: 14000, valid_from: Date.current
    }.merge(attrs))
  end

  def create_coupon(**attrs)
    build_coupon(**attrs).tap(&:save!)
  end
end
