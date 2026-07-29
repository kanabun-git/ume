require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  test "a normal first review from an IP is valid" do
    review = create_shop.reviews.build(reviewer_name: "利用者A", rating: 5, body: "良かったです", ip_address: "203.0.113.10")

    assert review.valid?
  end

  test "blocks a second review to the same shop from the same IP within 24 hours" do
    shop = create_shop
    shop.reviews.create!(reviewer_name: "利用者A", rating: 5, body: "1件目", ip_address: "203.0.113.10")

    second = shop.reviews.build(reviewer_name: "利用者A", rating: 4, body: "2件目", ip_address: "203.0.113.10")

    assert_not second.valid?
    assert_match(/24時間に1件まで/, second.errors[:base].join)
  end

  test "blocks a rapid second review from the same IP to a different shop" do
    create_shop.reviews.create!(reviewer_name: "利用者A", rating: 5, body: "1件目", ip_address: "203.0.113.10")

    second = create_shop.reviews.build(reviewer_name: "利用者A", rating: 4, body: "2件目", ip_address: "203.0.113.10")

    assert_not second.valid?
    assert_match(/間隔が短すぎます/, second.errors[:base].join)
  end

  test "does not rate-limit updates to an already-persisted review (e.g. status/reply changes)" do
    review = create_shop.reviews.create!(reviewer_name: "利用者A", rating: 5, body: "本文", ip_address: "203.0.113.10")

    assert review.update(status: :approved)
    assert review.update(shop_reply: "ありがとうございました")
  end

  test "a blank ip_address (e.g. seeded/console-created review) is not rate-limited" do
    shop = create_shop
    shop.reviews.create!(reviewer_name: "利用者A", rating: 5, body: "1件目", ip_address: nil)

    second = shop.reviews.build(reviewer_name: "利用者B", rating: 4, body: "2件目", ip_address: nil)

    assert second.valid?
  end
end
