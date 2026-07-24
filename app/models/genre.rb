class Genre < ApplicationRecord
  has_many :shops, dependent: :restrict_with_error

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/, message: "は半角英数字とハイフンのみ使用できます" }

  default_scope { order(:position, :name) }
end
