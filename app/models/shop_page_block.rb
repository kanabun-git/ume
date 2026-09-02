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
    price_table: 9,
    shop_info: 10,
    recruiting: 11,
    quick_nav: 12
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
    "price_table" => "料金表・オプション表",
    "shop_info" => "店舗情報",
    "recruiting" => "求人情報",
    "quick_nav" => "クイックメニュー"
  }.freeze

  # This block's editor has no image/content fields of its own for these
  # types -- unlike free_text/movie/price_table, the content is pulled
  # live from elsewhere in the admin screens, so a shop admin looking for
  # an upload field on the block's own edit screen won't find one. Shown
  # on the block edit form so that isn't mistaken for a missing feature.
  CONTENT_SOURCE_HINTS = {
    "image_gallery" => "「店舗情報編集」で登録した店舗写真がそのまま表示されます。この画面に写真をアップロードする欄はありません。",
    "new_girls" => "「在籍キャスト管理」で「体験入店」に設定したキャストが表示されます。",
    "manager_recommended" => "「在籍キャスト管理」で「店長おすすめ」に設定したキャストが表示されます。",
    "diaries_list" => "在籍キャストが投稿した写メ日記が新しい順に表示されます。",
    "weekly_schedule" => "「出勤予定一括登録」で登録した直近1週間の出勤予定が表示されます。",
    "ranking" => "口コミ件数の多いキャスト順に自動的に表示されます(手動での並び替えはできません)。",
    "coupon" => "「クーポン管理」で登録した現在有効なクーポンが表示されます。",
    "shop_info" => "「店舗情報編集」で登録した住所・電話番号・営業時間・料金・交通費・対応エリアがそのまま表示されます。",
    "recruiting" => "「店舗情報編集」の求人情報(コンパニオン募集・スタッフ募集・募集メッセージ)がそのまま表示されます。募集していない場合、このブロックは自動的に表示されません。",
    "quick_nav" => "在籍キャスト・写メ日記・週間出勤・動画・クーポン・口コミ・求人情報など、実際にこのページに表示されている項目へのジャンプメニューが自動的に作られます(存在しない項目は表示されません)。見出しの色帯を消して細いメニューバーとして使いたい場合は「タイトル帯・枠を非表示にする」をオンにしてください。"
  }.freeze

  belongs_to :shop
  has_one_attached :video_file

  # Set by Admin::VideosController only: 体験動画 uploaded there come from
  # the platform admin (a trusted role), not a shop, so the normal 50MB
  # shop-facing cap doesn't apply.
  attr_accessor :unlimited_video_size

  enum :block_type, BLOCK_TYPES

  before_validation :normalize_settings_rows

  validates :block_type, presence: true
  validates :background_opacity, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validates_attached_video :video_file

  default_scope { order(:position) }
  scope :visible, -> { where(visible: true) }
  # Matches movie blocks with either an uploaded video_file or a video_url
  # set in settings — a file-only upload has no video_url, so checking
  # settings alone (the original implementation) silently excluded it from
  # every public video listing.
  scope :with_video, lambda {
    movie.left_joins(:video_file_attachment).where(
      "shop_page_blocks.settings->>'video_url' IS NOT NULL AND shop_page_blocks.settings->>'video_url' != '' OR active_storage_attachments.id IS NOT NULL"
    )
  }

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

  def skip_video_size_limit?
    unlimited_video_size.present?
  end

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
