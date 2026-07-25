class Area < ApplicationRecord
  # Japan's conventional 8-region grouping, in display order.
  REGIONS = ["北海道", "東北", "関東", "中部", "関西", "中国・四国", "九州", "沖縄"].freeze

  # Regions the site actually covers at this stage of rollout. Prefectures
  # outside these are kept out of the public region picker until launched.
  ACTIVE_REGIONS = ["関東", "中部"].freeze

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

  # Routes look this model up by slug (`param: :slug`); without this,
  # `area_path(area)` would build URLs from the numeric id instead.
  def to_param
    slug
  end
end
