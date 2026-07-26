class Shop < ApplicationRecord
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

  validates :name, presence: true

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
