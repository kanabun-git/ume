class ReviewReplyTemplate < ApplicationRecord
  belongs_to :shop

  validates :title, presence: true
  validates :body, presence: true

  default_scope { order(:title) }
end
