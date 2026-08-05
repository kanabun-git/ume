class DiaryEntry < ApplicationRecord
  include AttachedImageValidatable
  include AttachedVideoValidatable

  belongs_to :cast
  has_many_attached :images
  has_one_attached :video

  enum :status, { draft: 0, published: 1 }, default: :draft

  validates :title, presence: true
  validates :body, presence: true
  validates_attached_images :images
  validates_attached_video :video

  scope :visible, -> { published.where("published_at <= ?", Time.current) }
  default_scope { order(published_at: :desc, created_at: :desc) }

  before_save :set_published_at, if: -> { published? && published_at.blank? }

  # Platform admins can moderate individual diary photos without removing
  # the whole entry; public pages must only ever render this, never
  # `images` directly, or a hidden photo would still leak out.
  def visible_images
    images.reject(&:hidden?)
  end

  def video_hidden?
    video.attached? && video.attachment.hidden?
  end

  # True while a published entry's published_at is still in the future —
  # it's saved and will go live on its own, but isn't in `visible` yet.
  def scheduled?
    published? && published_at.present? && published_at > Time.current
  end

  # True once every uploaded image and the video (if any) have been hidden
  # by admin moderation, as opposed to nothing ever having been uploaded —
  # the two cases show different placeholders (see
  # ApplicationHelper#diary_thumb_tag).
  def content_removed_by_moderation?
    return false unless images.attached? || video.attached?
    return false if visible_images.any?
    return false if video.attached? && !video_hidden?

    true
  end

  private

  def set_published_at
    self.published_at = Time.current
  end
end
