class SiteSetting < ApplicationRecord
  MAX_IMAGE_FILE_SIZE = 5.megabytes
  ALLOWED_IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze

  # "Now Printing" placeholder shown wherever a photo hasn't been uploaded
  # yet: one image for portrait (3:4) spots like cast/diary thumbnails, one
  # for landscape spots like the shop photo gallery.
  has_one_attached :nowprinting_portrait_image
  has_one_attached :nowprinting_landscape_image

  validate :validate_nowprinting_portrait_image
  validate :validate_nowprinting_landscape_image

  # This table only ever holds a single row: site-wide toggles like
  # maintenance mode don't belong to any particular record, so rather than
  # threading a settings object through every controller, callers just ask
  # for "the" settings via .instance.
  def self.instance
    first_or_create!
  end

  private

  def validate_nowprinting_portrait_image
    validate_image_attachment(:nowprinting_portrait_image)
  end

  def validate_nowprinting_landscape_image
    validate_image_attachment(:nowprinting_landscape_image)
  end

  def validate_image_attachment(attachment_name)
    attachment = public_send(attachment_name)
    return unless attachment.attached?

    blob = attachment.blob
    if blob.byte_size > MAX_IMAGE_FILE_SIZE
      errors.add(attachment_name, "は5MBまでのファイルを指定してください")
    end
    unless ALLOWED_IMAGE_CONTENT_TYPES.include?(blob.content_type)
      errors.add(attachment_name, "はJPEG・PNG・WEBP形式の画像を指定してください")
    end
  end
end
