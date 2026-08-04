class Member < ApplicationRecord
  # Individual site visitors (個人会員): self-registered, unlike User which
  # covers the three staff roles (cast/shop_admin/platform_admin) that are
  # always provisioned by someone else. Kept as a separate Devise scope so
  # member accounts never show up in Admin::UsersController and never gain
  # any staff-side authorization.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :favorites, dependent: :destroy
  has_many :favorite_casts, through: :favorites, source: :cast

  validates :name, presence: true

  def favorited?(cast)
    favorite_casts.include?(cast)
  end
end
