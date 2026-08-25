class Area < ApplicationRecord
  # Japan's conventional 8-region grouping, in display order.
  REGIONS = ["北海道", "東北", "関東", "中部", "関西", "中国・四国", "九州", "沖縄"].freeze

  # Regions the site actually covers at this stage of rollout. Prefectures
  # outside these are kept out of the public region picker until launched.
  ACTIVE_REGIONS = ["関東", "中部"].freeze

  # All 47 prefectures, keyed by their bare name (no 都/道/府/県 suffix,
  # matching how ShopProspectDistrict#prefecture is actually entered -- see
  # .region_for_prefecture_name). Lets a brand-new top-level Area be
  # registered with a valid region with no admin input.
  PREFECTURE_REGIONS = {
    "北海道" => "北海道",
    "青森" => "東北", "岩手" => "東北", "宮城" => "東北", "秋田" => "東北", "山形" => "東北", "福島" => "東北",
    "東京" => "関東", "神奈川" => "関東", "埼玉" => "関東", "千葉" => "関東", "茨城" => "関東", "栃木" => "関東", "群馬" => "関東",
    "新潟" => "中部", "富山" => "中部", "石川" => "中部", "福井" => "中部", "山梨" => "中部", "長野" => "中部", "岐阜" => "中部", "静岡" => "中部", "愛知" => "中部",
    "大阪" => "関西", "京都" => "関西", "兵庫" => "関西", "奈良" => "関西", "和歌山" => "関西", "滋賀" => "関西", "三重" => "関西",
    "鳥取" => "中国・四国", "島根" => "中国・四国", "岡山" => "中国・四国", "広島" => "中国・四国", "山口" => "中国・四国",
    "徳島" => "中国・四国", "香川" => "中国・四国", "愛媛" => "中国・四国", "高知" => "中国・四国",
    "福岡" => "九州", "佐賀" => "九州", "長崎" => "九州", "熊本" => "九州", "大分" => "九州", "宮崎" => "九州", "鹿児島" => "九州",
    "沖縄" => "沖縄"
  }.freeze

  belongs_to :parent, class_name: "Area", optional: true, inverse_of: :children
  has_many :children, class_name: "Area", foreign_key: :parent_id, dependent: :nullify, inverse_of: :parent
  has_many :shops, dependent: :restrict_with_error

  validates :name, presence: true
  # Slugs are entered by the platform admin (not auto-generated from the
  # Japanese name) since transliteration of Japanese place names doesn't
  # produce a usable URL segment.
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/, message: "は半角英数字とハイフンのみ使用できます" }
  validates :region, presence: true, inclusion: { in: REGIONS }, if: :prefecture?

  default_scope { order(:position, :name) }

  scope :active_region, -> { where(region: ACTIVE_REGIONS) }

  def prefecture?
    parent_id.nil?
  end

  # "東京都"/"大阪府"/"北海道"/etc. all resolve, since admins enter the
  # prefecture name freely elsewhere (e.g. ShopProspectDistrict#prefecture).
  def self.region_for_prefecture_name(name)
    name = name.to_s
    PREFECTURE_REGIONS[name] || PREFECTURE_REGIONS[name.sub(/(都|道|府|県)\z/, "")]
  end

  # A slug that satisfies the format/uniqueness validation with zero admin
  # input -- used when an Area is registered with one click (see
  # Admin::ShopProspectDistrictsController#register_area). Not meant to be
  # a good public-facing URL; rename it from "エリア管理" once created.
  def self.generate_unique_slug
    loop do
      slug = "area-#{SecureRandom.hex(4)}"
      break slug unless exists?(slug: slug)
    end
  end

  # Routes look this model up by slug (`param: :slug`); without this,
  # `area_path(area)` would build URLs from the numeric id instead.
  def to_param
    slug
  end
end
