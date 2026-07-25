class ShopPageBlock < ApplicationRecord
  # The set of block types a shop admin can compose a store page from.
  # Order here doubles as the option order in the "add block" form.
  BLOCK_TYPES = {
    image_gallery: 0,
    new_girls: 1,
    manager_recommended: 2,
    diaries_list: 3,
    weekly_schedule: 4,
    ranking: 5,
    free_text: 6,
    movie: 7,
    coupon: 8,
  }.freeze

  LABELS = {
    "image_gallery" => "店舗フォトギャラリー",
    "new_girls" => "新人・体験入店",
    "manager_recommended" => "店長おすすめ",
    "diaries_list" => "写メ日記",
    "weekly_schedule" => "週間出勤",
    "ranking" => "口コミランキング",
    "free_text" => "フリーテキスト",
    "movie" => "動画",
    "coupon" => "クーポン",
  }.freeze

  belongs_to :shop

  enum :block_type, BLOCK_TYPES

  validates :block_type, presence: true
  validates :background_opacity, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  default_scope { order(:position) }
  scope :visible, -> { where(visible: true) }

  def label
    title.presence || LABELS.fetch(block_type, block_type)
  end

  # Inline style for the section band / wrapper, driven by the admin-editable
  # background color + opacity (hex color converted to rgba so opacity works
  # independently of the site's own theme colors).
  def background_style
    return "" if background_color.blank?

    r, g, b = background_color.delete("#").scan(/../).map { |h| h.to_i(16) }
    "background-color: rgba(#{r}, #{g}, #{b}, #{background_opacity});"
  end
end
