namespace :site_settings do
  # Maps each SiteSetting image attachment to the static asset filename
  # (without extension) that ApplicationHelper falls back to when nothing is
  # attached. See app/helpers/application_helper.rb.
  EXPORT_DEFAULTS_MAPPING = {
    nowprinting_portrait_image: "nowprinting_portrait",
    nowprinting_landscape_image: "nowprinting_landscape",
    logo_horizontal_image: "site_logo_horizontal",
    logo_square_large_image: "site_logo_square",
    logo_square_small_image: "site_logo_square_small",
    removed_content_portrait_image: "removed_content_portrait",
    removed_content_landscape_image: "removed_content_landscape",
    index_eyecatch_image: "index_img",
    index_map_image: "japan_map"
  }.freeze

  CONTENT_TYPE_EXTENSIONS = {
    "image/jpeg" => "jpg",
    "image/png" => "png",
    "image/webp" => "webp"
  }.freeze

  desc "Copy currently admin-uploaded SiteSetting images into app/assets/images so they become the checked-in defaults"
  task export_defaults: :environment do
    setting = SiteSetting.instance
    dest_dir = Rails.root.join("app/assets/images")

    EXPORT_DEFAULTS_MAPPING.each do |attachment_name, base_name|
      attachment = setting.public_send(attachment_name)

      unless attachment.attached?
        puts "#{attachment_name}: 未アップロードのためスキップ"
        next
      end

      ext = CONTENT_TYPE_EXTENSIONS.fetch(attachment.blob.content_type, "bin")
      dest_path = dest_dir.join("#{base_name}.#{ext}")
      File.binwrite(dest_path, attachment.download)
      puts "#{attachment_name}: #{dest_path} に書き出しました"
    end
  end
end
