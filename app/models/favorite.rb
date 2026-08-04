class Favorite < ApplicationRecord
  belongs_to :member
  belongs_to :cast

  validates :cast_id, uniqueness: { scope: :member_id }
end
