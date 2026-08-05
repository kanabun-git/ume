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
  has_many :shop_favorites, dependent: :destroy
  has_many :favorite_shops, through: :shop_favorites, source: :shop
  has_many :reviews, dependent: :nullify
  has_many :present_ticket_entries, dependent: :destroy

  validates :name, presence: true

  def favorited?(cast)
    favorite_casts.include?(cast)
  end

  def favorited_shop?(shop)
    favorite_shops.include?(shop)
  end

  def approved_review_count
    reviews.approved.count
  end

  def rank
    MemberRank.for_approved_count(approved_review_count)
  end

  def next_rank
    MemberRank.where("min_approved_count > ?", approved_review_count).reorder(:min_approved_count).first
  end
end
