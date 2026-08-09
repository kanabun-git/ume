class Shop < ApplicationRecord
  include AttachedImageValidatable

  belongs_to :area
  belongs_to :genre
  belongs_to :plan
  has_many :users, dependent: :nullify
  has_many :casts, dependent: :destroy
  has_many :diary_entries, through: :casts
  has_many :shifts, through: :casts
  has_many :reviews, dependent: :destroy
  has_many :shop_subscriptions, dependent: :destroy
  has_many :shop_page_blocks, dependent: :destroy
  has_many :cast_page_blocks, dependent: :destroy
  has_many :review_reply_templates, dependent: :destroy
  has_many :present_tickets, dependent: :destroy
  has_many :coupons, dependent: :destroy
  has_many :shop_memberships, dependent: :destroy
  has_many :shop_member_ranks, dependent: :destroy
  has_many_attached :photos
  has_one_attached :page_background_image

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
  validate :validate_page_background_image

  after_create :seed_default_page_blocks
  after_create :seed_default_cast_page_blocks

  scope :visible, -> { approved }
  scope :ranked, -> { visible.joins(:plan).order(Arel.sql("plans.priority_weight * shops.view_count DESC")) }
  # Areas can be a prefecture (region set directly) or a city belonging to
  # one (region only set on its parent), so match either.
  scope :in_region, lambda { |region|
    joins("INNER JOIN areas ON areas.id = shops.area_id")
      .joins("LEFT JOIN areas parent_areas ON parent_areas.id = areas.parent_id")
      .where("areas.region = :region OR parent_areas.region = :region", region: region)
  }

  def approved_reviews
    reviews.approved
  end

  # The "地方" (Kanto/Chubu/...) this shop belongs to — area can be either
  # a prefecture (region set directly) or a city (region only on its
  # parent), mirroring the fallback in the .in_region scope above.
  def region
    area.prefecture? ? area.region : area.parent&.region
  end

  # "Zeroお勧め" badge: shown for shops on a paid plan, or for any shop the
  # platform admin has explicitly flagged regardless of plan.
  def zero_recommended_badge?
    zero_recommended? || plan.monthly_fee.positive?
  end

  def average_rating
    approved_reviews.average(:rating)&.round(1)
  end

  # "PR" badge: unlike zero_recommended_badge? (an editorial call the
  # platform admin makes), this one the shop admin sets on themselves —
  # a time-boxed self-promotion slot with no billing enforcement yet
  # (see ShopSubscription's note in docs/architecture.md).
  def pr_badge_active?
    pr_badge_until.present? && pr_badge_until > Time.current
  end

  # Inline style for the store detail page's theme wrapper -- background
  # color, base text color, and an override of the site's --brand/--brand-dark
  # CSS custom properties so every badge/button/link nested inside picks up
  # the shop's chosen accent color instead of the site-wide pink. The
  # background image (if any) is added separately by the view, since
  # resolving its URL needs a view context.
  def page_theme_style
    styles = []
    styles << "background-color: #{page_background_color};" if page_background_color.present?
    styles << "color: #{page_text_color};" if page_text_color.present?
    if page_accent_color.present?
      styles << "--brand: #{page_accent_color};"
      styles << "--brand-dark: #{darkened_page_accent_color};"
    end
    styles.join(" ")
  end

  def darkened_page_accent_color(amount = 0.2)
    r, g, b = page_accent_color.delete("#").scan(/../).map { |h| h.to_i(16) }
    format("#%02x%02x%02x", *[r, g, b].map { |c| (c * (1 - amount)).round.clamp(0, 255) })
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

  private

  def validate_page_background_image
    return unless page_background_image.attached?

    blob = page_background_image.blob
    if blob.byte_size > AttachedImageValidatable::MAX_FILE_SIZE
      errors.add(:page_background_image, "は5MBまでのファイルを指定してください")
    end
    unless AttachedImageValidatable::ALLOWED_CONTENT_TYPES.include?(blob.content_type)
      errors.add(:page_background_image, "はJPEG・PNG・WEBP形式の画像を指定してください")
    end
  end
end
