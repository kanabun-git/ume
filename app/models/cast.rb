class Cast < ApplicationRecord
  # Fixed option list for the shop search's カップサイズ filter (shops.rb
  # controller); cup itself stays a free-text column since some casts list
  # non-standard values, but the filter only needs to offer the common ones.
  CUP_OPTIONS = %w[A B C D E F G H I J].freeze

  include AttachedImageValidatable

  belongs_to :shop
  belongs_to :user, optional: true, inverse_of: :cast_profile
  has_many :diary_entries, dependent: :destroy
  has_many :shifts, dependent: :destroy
  has_many :reviews, dependent: :nullify
  has_many_attached :photos

  accepts_nested_attributes_for :user

  enum :status, { active: 0, inactive: 1 }, default: :active

  validates :name, presence: true
  validates_attached_images :photos

  before_validation :assign_login_user_defaults

  scope :visible, -> { active }
  scope :trial, -> { where(is_trial: true) }
  scope :manager_recommended, -> { where(manager_recommended: true) }
  scope :pick_up, -> { where(pick_up: true) }

  def upcoming_shifts
    shifts.where(status: :scheduled).where("work_date >= ?", Date.current).order(:work_date, :start_time)
  end

  # Platform admins can moderate individual photos without removing the
  # whole cast; public pages must only ever render this, never `photos`
  # directly, or a hidden photo would still leak out.
  def visible_photos
    photos.reject(&:hidden?)
  end

  private

  # When a shop admin creates a login account for a cast via the nested
  # form, the account must inherit the shop/role — it isn't user-editable.
  def assign_login_user_defaults
    return unless user&.new_record?

    user.shop_id = shop_id
    user.role = :cast
    user.name = name if user.name.blank?
  end
end
