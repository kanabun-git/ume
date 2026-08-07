class MemberRank < ApplicationRecord
  has_one_attached :card_image

  validates :name, presence: true
  validates :min_approved_count, presence: true, numericality: { greater_than_or_equal_to: 0 }, uniqueness: true
  validate :validate_card_image

  default_scope { order(:min_approved_count) }

  # The highest-threshold rank a member with `approved_count` approved
  # reviews qualifies for, or nil if no rank's threshold is low enough
  # (e.g. no ranks configured yet, or the lowest one requires 1+).
  def self.for_approved_count(approved_count)
    where("min_approved_count <= ?", approved_count).reorder(min_approved_count: :desc).first
  end

  private

  def validate_card_image
    return unless card_image.attached?

    blob = card_image.blob
    if blob.byte_size > AttachedImageValidatable::MAX_FILE_SIZE
      errors.add(:card_image, "は5MBまでのファイルを指定してください")
    end
    unless AttachedImageValidatable::ALLOWED_CONTENT_TYPES.include?(blob.content_type)
      errors.add(:card_image, "はJPEG・PNG・WEBP形式の画像を指定してください")
    end
  end
end
