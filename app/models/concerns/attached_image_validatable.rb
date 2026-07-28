module AttachedImageValidatable
  extend ActiveSupport::Concern

  MAX_IMAGES = 10
  MAX_FILE_SIZE = 5.megabytes
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze

  class_methods do
    def validates_attached_images(attachment_name)
      validate { validate_attached_images(attachment_name) }
    end
  end

  private

  def validate_attached_images(attachment_name)
    attachment = public_send(attachment_name)
    return unless attachment.attached?

    if attachment.count > AttachedImageValidatable::MAX_IMAGES
      errors.add(attachment_name, "は#{AttachedImageValidatable::MAX_IMAGES}枚までアップロードできます")
    end

    attachment.each do |file|
      blob = file.blob
      if blob.byte_size > AttachedImageValidatable::MAX_FILE_SIZE
        errors.add(attachment_name, "に5MBを超えるファイルが含まれています(#{blob.filename})")
      end
      unless AttachedImageValidatable::ALLOWED_CONTENT_TYPES.include?(blob.content_type)
        errors.add(attachment_name, "にJPEG・PNG・WEBP以外の形式のファイルが含まれています(#{blob.filename})")
      end
    end
  end
end
