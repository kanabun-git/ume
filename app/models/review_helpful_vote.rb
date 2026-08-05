class ReviewHelpfulVote < ApplicationRecord
  belongs_to :review

  validates :ip_address, presence: true, uniqueness: { scope: :review_id }
end
