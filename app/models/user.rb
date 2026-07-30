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

  # Lets a platform admin hand a brand-new account to its owner as a
  # copy/paste link (see Admin::UsersController#issue_account_setup_link)
  # instead of the admin choosing/knowing the initial password themselves.
  # `set_reset_password_token` is Devise's own token issuance — reusing it
  # means the link is verified/consumed by Devise's existing password-reset
  # flow (edit_user_password_path) with no new controller code needed.
  # Unlike `send_reset_password_instructions`, this does not send any email.
  def generate_account_setup_token
    set_reset_password_token
  end
end
