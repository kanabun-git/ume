class CastPageBlock < ApplicationRecord
  # The set of block types a shop admin can compose a girl's detail page
  # from. Order here doubles as the option order in the "add block" form.
  BLOCK_TYPES = {
    main_gallery: 0,
    profile: 1,
    qa: 2,
    appeal_comment: 3,
    selling_points: 4,
    manager_comment: 5,
    diary: 6,
    shift: 7,
    reviews: 8,
    free_text: 9,
  }.freeze

  LABELS = {
    "main_gallery" => "メイン写真",
    "profile" => "プロフィール",
    "qa" => "女の子に質問",
    "appeal_comment" => "アピールコメント",
    "selling_points" => "セールスポイント",
    "manager_comment" => "店長からのコメント",
    "diary" => "投稿!!写メ日記",
    "shift" => "出勤情報",
    "reviews" => "口コミ",
    "free_text" => "フリーテキスト",
  }.freeze

  belongs_to :shop

  enum :block_type, BLOCK_TYPES
  enum :layout_column, { main: 0, side: 1 }, prefix: true

  validates :block_type, presence: true
  validates :background_opacity, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  default_scope { order(:layout_column, :position) }
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
