require "test_helper"

class ReviewHelpfulVoteTest < ActiveSupport::TestCase
  test "the same IP address cannot vote the same review twice" do
    review = create_shop.reviews.create!(reviewer_name: "A", rating: 5, body: "良い店でした", status: :approved)
    review.review_helpful_votes.create!(ip_address: "203.0.113.1")

    duplicate = review.review_helpful_votes.build(ip_address: "203.0.113.1")

    assert_not duplicate.valid?
  end

  test "different IP addresses can each vote the same review" do
    review = create_shop.reviews.create!(reviewer_name: "A", rating: 5, body: "良い店でした", status: :approved)
    review.review_helpful_votes.create!(ip_address: "203.0.113.1")

    other = review.review_helpful_votes.build(ip_address: "203.0.113.2")

    assert other.valid?
  end
end
