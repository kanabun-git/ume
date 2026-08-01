module AttachedVideoValidatable
  extend ActiveSupport::Concern

  MAX_VIDEO_FILE_SIZE = 50.megabytes
  ALLOWED_VIDEO_CONTENT_TYPES = %w[video/mp4 video/quicktime video/webm].freeze

  class_methods do
    def validates_attached_video(attachment_name)
      validate { validate_attached_video(attachment_name) }
    end
  end

  private

  def validate_attached_video(attachment_name)
    attachment = public_send(attachment_name)
    return unless attachment.attached?

    blob = attachment.blob
    if blob.byte_size > AttachedVideoValidatable::MAX_VIDEO_FILE_SIZE
      errors.add(attachment_name, "は50MBまでの動画をアップロードできます")
    end
    unless AttachedVideoValidatable::ALLOWED_VIDEO_CONTENT_TYPES.include?(blob.content_type)
      errors.add(attachment_name, "はMP4・MOV・WEBM形式の動画をアップロードできます")
    end
  end
end
