class Cast < ApplicationRecord
  belongs_to :shop
  belongs_to :user, optional: true, inverse_of: :cast_profile
  has_many :diary_entries, dependent: :destroy
  has_many :shifts, dependent: :destroy
  has_many :reviews, dependent: :nullify
  has_many :cast_page_blocks, dependent: :destroy
  has_many_attached :photos

  accepts_nested_attributes_for :user

  enum :status, { active: 0, inactive: 1 }, default: :active

  validates :name, presence: true

  before_validation :assign_login_user_defaults
  after_create :seed_default_page_blocks

  scope :visible, -> { active }
  scope :trial, -> { where(is_trial: true) }
  scope :manager_recommended, -> { where(manager_recommended: true) }
  scope :pick_up, -> { where(pick_up: true) }

  def upcoming_shifts
    shifts.where(status: :scheduled).where("work_date >= ?", Date.current).order(:work_date, :start_time)
  end

  # The default page composition for a newly created cast, split across the
  # two columns of the girl detail page layout. Shop admins can freely
  # add/remove/reorder/hide blocks afterwards — this just avoids a blank
  # page on day one.
  MAIN_COLUMN_BLOCK_TYPES = %w[main_gallery qa appeal_comment selling_points manager_comment diary].freeze
  SIDE_COLUMN_BLOCK_TYPES = %w[profile shift reviews].freeze

  def seed_default_page_blocks
    return if cast_page_blocks.any?

    MAIN_COLUMN_BLOCK_TYPES.each_with_index do |block_type, index|
      cast_page_blocks.create!(block_type: block_type, layout_column: :main, position: index)
    end
    SIDE_COLUMN_BLOCK_TYPES.each_with_index do |block_type, index|
      cast_page_blocks.create!(block_type: block_type, layout_column: :side, position: index)
    end
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
