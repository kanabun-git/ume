require "test_helper"

class CouponUsageTest < ActiveSupport::TestCase
  test "defaults to net_reservation when no usage_type is given" do
    coupon = create_shop.coupons.create!(
      title: "テストクーポン", course_name: "60分", regular_price: 20000, discounted_price: 14000, valid_from: Date.current
    )

    usage = coupon.coupon_usages.create!

    assert usage.net_reservation?
  end

  test "destroying a coupon destroys its usage log" do
    coupon = create_shop.coupons.create!(
      title: "テストクーポン", course_name: "60分", regular_price: 20000, discounted_price: 14000, valid_from: Date.current
    )
    usage = coupon.coupon_usages.create!(usage_type: :manual)

    coupon.destroy

    assert_not CouponUsage.exists?(usage.id)
  end
end
