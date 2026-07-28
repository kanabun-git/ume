class DiaryEntry < ApplicationRecord
  belongs_to :cast
  has_many_attached :images

  enum :status, { draft: 0, published: 1 }, default: :draft

  validates :title, presence: true
  validates :body, presence: true

  scope :visible, -> { published.where("published_at <= ?", Time.current) }
  default_scope { order(published_at: :desc, created_at: :desc) }

  before_save :set_published_at, if: -> { published? && published_at.blank? }

  # Platform admins can moderate individual diary photos without removing
  # the whole entry; public pages must only ever render this, never
  # `images` directly, or a hidden photo would still leak out.
  def visible_images
    images.reject(&:hidden?)
  end

  private

  def set_published_at
    self.published_at = Time.current
  end
end
