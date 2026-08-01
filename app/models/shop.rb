class Shop < ApplicationRecord
  include AttachedImageValidatable

  belongs_to :area
  belongs_to :genre
  belongs_to :plan
  has_many :users, dependent: :nullify
  has_many :casts, dependent: :destroy
  has_many :diary_entries, through: :casts
  has_many :reviews, dependent: :destroy
  has_many :shop_subscriptions, dependent: :destroy
  has_many :shop_page_blocks, dependent: :destroy
  has_many :cast_page_blocks, dependent: :destroy
  has_many_attached :photos

  enum :status, { pending: 0, approved: 1, suspended: 2 }, default: :pending
  # How times past midnight are shown on this shop's pages:
  # standard -> 02:00, extended -> 26:00.
  enum :time_display_format, { standard: 0, extended: 1 }, default: :standard, prefix: :time_format

  TIME_DISPLAY_FORMAT_LABELS = {
    "standard" => "24時間表記 (例: 深夜2時 → 02:00)",
    "extended" => "延長表記 (例: 深夜2時 → 26:00)"
  }.freeze

  # Fixed price ceilings offered by the shop search's 料金 filter
  # (shops_controller#index matches shops.min_price <= 選択値).
  PRICE_FILTER_OPTIONS = [
    ["15,000円以下", 15_000],
    ["20,000円以下", 20_000],
    ["25,000円以下", 25_000],
    ["30,000円以下", 30_000]
  ].freeze

  validates :name, presence: true
  validates_attached_images :photos

  after_create :seed_default_page_blocks
  after_create :seed_default_cast_page_blocks

  scope :visible, -> { approved }
  scope :ranked, -> { visible.joins(:plan).order(Arel.sql("plans.priority_weight * shops.view_count DESC")) }

  def approved_reviews
    reviews.approved
  end

  def average_rating
    approved_reviews.average(:rating)&.round(1)
  end

  # The default page composition for a newly created shop. Shop admins can
  # freely add/remove/reorder/hide blocks afterwards from their dashboard —
  # this just avoids a blank page on day one.
  DEFAULT_BLOCK_TYPES = %w[image_gallery new_girls diaries_list weekly_schedule coupon free_text].freeze

  def seed_default_page_blocks
    return if shop_page_blocks.any?

    DEFAULT_BLOCK_TYPES.each_with_index do |block_type, index|
      shop_page_blocks.create!(block_type: block_type, position: index)
    end
  end

  # The default girl detail page composition, shared by every cast at this
  # shop, split across the two columns of the layout. Shop admins can freely
  # add/remove/reorder/hide blocks afterwards — this just avoids a blank
  # page on day one.
  CAST_MAIN_COLUMN_BLOCK_TYPES = %w[main_gallery qa appeal_comment selling_points manager_comment diary].freeze
  CAST_SIDE_COLUMN_BLOCK_TYPES = %w[profile shift reviews].freeze

  def seed_default_cast_page_blocks
    return if cast_page_blocks.any?

    CAST_MAIN_COLUMN_BLOCK_TYPES.each_with_index do |block_type, index|
      cast_page_blocks.create!(block_type: block_type, layout_column: :main, position: index)
    end
    CAST_SIDE_COLUMN_BLOCK_TYPES.each_with_index do |block_type, index|
      cast_page_blocks.create!(block_type: block_type, layout_column: :side, position: index)
    end
  end
end
