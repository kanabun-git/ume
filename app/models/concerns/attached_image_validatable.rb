module AttachedImageValidatable
  extend ActiveSupport::Concern

  MAX_IMAGES = 5
  MAX_FILE_SIZE = 5.megabytes
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze

  class_methods do
    def validates_attached_images(attachment_name)
      validate { validate_attached_images(attachment_name) }
    end
  end

  # Validates newly-selected uploads against the shared size/type rules and
  # this record's existing attachment count, without attaching anything.
  # Callers (see AttachesImages) run this before calling `.attach`, because
  # `.attach` persists immediately regardless of the record's validity —
  # checking first means a rejected upload never touches storage.
  def validate_new_images(attachment_name, new_files)
    new_files = Array(new_files).reject(&:blank?)
    return [] if new_files.empty?

    messages = []
    existing_count = public_send(attachment_name).count

    if existing_count + new_files.size > AttachedImageValidatable::MAX_IMAGES
      messages << "は合計#{AttachedImageValidatable::MAX_IMAGES}枚までアップロードできます(現在#{existing_count}枚)"
    end

    new_files.each do |file|
      if file.size > AttachedImageValidatable::MAX_FILE_SIZE
        messages << "に5MBを超えるファイルが含まれています(#{file.original_filename})"
      end
      unless AttachedImageValidatable::ALLOWED_CONTENT_TYPES.include?(file.content_type)
        messages << "にJPEG・PNG・WEBP以外の形式のファイルが含まれています(#{file.original_filename})"
      end
    end

    messages
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
