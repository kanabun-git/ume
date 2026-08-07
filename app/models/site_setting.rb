class SiteSetting < ApplicationRecord
  MAX_IMAGE_FILE_SIZE = 5.megabytes
  ALLOWED_IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze

  # Single-image site assets, each swappable from 運営管理画面 > サイト設定
  # without a deploy: the "Now Printing" placeholders shown wherever a photo
  # hasn't been uploaded yet (portrait for cast/diary thumbnails, landscape
  # for the shop photo gallery), the site logo in its three standard shapes
  # (header, OGP share image, favicon), the "removed by moderation"
  # placeholders shown when a photo/video was hidden rather than never
  # uploaded, the top gate/splash page's eyecatch + region map images, and
  # the member card design shown on a signed-up member's mypage.
  IMAGE_ATTACHMENTS = %i[
    nowprinting_portrait_image
    nowprinting_landscape_image
    logo_horizontal_image
    logo_square_large_image
    logo_square_small_image
    removed_content_portrait_image
    removed_content_landscape_image
    index_eyecatch_image
    index_map_image
    membership_card_image
  ].freeze

  IMAGE_ATTACHMENTS.each { |name| has_one_attached name }

  validate :validate_image_attachments

  # This table only ever holds a single row: site-wide toggles like
  # maintenance mode don't belong to any particular record, so rather than
  # threading a settings object through every controller, callers just ask
  # for "the" settings via .instance.
  def self.instance
    first_or_create!
  end

  private

  def validate_image_attachments
    IMAGE_ATTACHMENTS.each do |attachment_name|
      attachment = public_send(attachment_name)
      next unless attachment.attached?

      blob = attachment.blob
      if blob.byte_size > MAX_IMAGE_FILE_SIZE
        errors.add(attachment_name, "は5MBまでのファイルを指定してください")
      end
      unless ALLOWED_IMAGE_CONTENT_TYPES.include?(blob.content_type)
        errors.add(attachment_name, "はJPEG・PNG・WEBP形式の画像を指定してください")
      end
    end
  end
end
