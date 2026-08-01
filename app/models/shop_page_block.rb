class ShopPageBlock < ApplicationRecord
  include AttachedVideoValidatable

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
    price_table: 9
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
    "price_table" => "料金表・オプション表"
  }.freeze

  belongs_to :shop
  has_one_attached :video_file

  enum :block_type, BLOCK_TYPES

  before_validation :normalize_settings_rows

  validates :block_type, presence: true
  validates :background_opacity, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validates_attached_video :video_file

  default_scope { order(:position) }
  scope :visible, -> { where(visible: true) }
  scope :with_video, -> { movie.where("settings->>'video_url' IS NOT NULL AND settings->>'video_url' != ''") }

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

  private

  # The price_table row editor submits settings[rows][INDEX][label/value]
  # with numeric indices. When an admin removes a row from the middle, the
  # remaining indices skip a number, so Rails parses the submitted params as
  # a Hash (e.g. {"1"=>{...}, "2"=>{...}}) rather than an Array — normalize
  # it back to a plain, gap-free Array so views can rely on settings["rows"]
  # always being an Array.
  def normalize_settings_rows
    rows = settings["rows"]
    return unless rows.is_a?(Hash)

    settings["rows"] = rows.sort_by { |key, _| key.to_i }.map { |_, value| value }
  end
end
