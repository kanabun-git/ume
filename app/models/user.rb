class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  enum :role, { cast: 0, shop_admin: 1, platform_admin: 2 }, default: :cast

  belongs_to :shop, optional: true
  has_one :cast_profile, class_name: "Cast", foreign_key: :user_id, dependent: :nullify, inverse_of: :user

  validates :name, presence: true
  validates :shop_id, presence: true, if: -> { shop_admin? }
end
