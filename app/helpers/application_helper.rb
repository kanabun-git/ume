module ApplicationHelper
  STATUS_LABELS = {
    "Shop" => { "pending" => "承認待ち", "approved" => "承認済み", "suspended" => "停止中" },
    "Cast" => { "active" => "在籍中", "inactive" => "退店" },
    "DiaryEntry" => { "draft" => "下書き", "published" => "公開" },
    "Shift" => { "scheduled" => "予定", "cancelled" => "キャンセル" },
    "Review" => { "pending" => "承認待ち", "approved" => "承認済み", "rejected" => "却下" },
    "ShopSubscription" => { "active" => "契約中", "canceled" => "解約" },
    "ShopInquiry" => { "pending" => "未対応", "in_progress" => "対応中", "closed" => "対応済み" },
    "ShopProspect" => {
      "not_contacted" => "未アプローチ", "contacted" => "アプローチ済み",
      "negotiating" => "商談中", "won" => "成約", "lost" => "見送り"
    },
    "PresentTicket" => { "accepting" => "応募受付中", "drawn" => "抽選済み", "closed" => "終了" },
    "PresentTicketEntry" => { "pending" => "抽選待ち", "won" => "当選", "lost" => "落選" }
  }.freeze

  ROLE_LABELS = {
    "cast" => "キャスト",
    "shop_admin" => "店舗管理者",
    "platform_admin" => "運営者"
  }.freeze

  def status_label(record)
    STATUS_LABELS.dig(record.class.name, record.status) || record.status
  end

  def role_label(user)
    ROLE_LABELS[user.role] || user.role
  end

  # Badge shown in the review admin/moderation tables so it's obvious at a
  # glance which reviews the shop hasn't replied to yet.
  def review_reply_status_badge(review)
    if review.shop_reply.present?
      content_tag(:span, "返信済み", class: "badge")
    else
      content_tag(:span, "未返信", class: "badge warning")
    end
  end

  # Badge shown in 営業先候補一覧 so it's obvious at a glance which leads have
  # been emailed and, further, which of those actually clicked through (the
  # strongest signal that outreach is landing) -- see ShopProspectMailer and
  # ShopProspectOutreachController.
  def outreach_status_badge(prospect)
    if prospect.outreach_link_clicked_at.present?
      content_tag(:span, "クリック済み(#{l prospect.outreach_link_clicked_at, format: :short})", class: "badge")
    elsif prospect.outreach_email_sent_at.present?
      content_tag(:span, "送信済み(#{l prospect.outreach_email_sent_at, format: :short})", class: "badge muted")
    else
      content_tag(:span, "未送信", class: "badge warning")
    end
  end

  NOWPRINTING_IMAGE_DEFAULTS = {
    portrait: "nowprinting_portrait.png",
    landscape: "nowprinting_landscape.png"
  }.freeze

  # Renders the shared "Now Printing" placeholder, using the image uploaded
  # in 運営管理画面 > サイト設定 if one is set, falling back to the checked-in
  # default otherwise. orientation is :portrait (3:4 spots) or :landscape.
  def nowprinting_image_tag(orientation = :portrait, **html_options)
    attachment_name = orientation == :landscape ? :nowprinting_landscape_image : :nowprinting_portrait_image
    attachment = site_setting_singleton.public_send(attachment_name)

    if attachment.attached?
      image_tag(attachment, html_options)
    else
      image_tag(NOWPRINTING_IMAGE_DEFAULTS.fetch(orientation), html_options)
    end
  end

  # Returns the attached logo image for the given shape if the admin has
  # uploaded one via 運営管理画面 > サイト設定, or nil otherwise so callers
  # can fall back to their own default (text logo, static favicon, ...).
  # kind is :horizontal, :square_large, or :square_small.
  def site_logo(kind)
    attachment_name = :"logo_#{kind}_image"
    attachment = site_setting_singleton.public_send(attachment_name)
    attachment if attachment.attached?
  end

  # Static defaults for the top gate/splash page images, used whenever the
  # admin hasn't uploaded a replacement via 運営管理画面 > サイト設定.
  INDEX_IMAGE_DEFAULTS = {
    eyecatch: "index_img.png",
    map: "japan_map.png"
  }.freeze

  # Renders the top gate/splash page's eyecatch or region-picker map image,
  # using the file uploaded in 運営管理画面 > サイト設定 if one is set,
  # falling back to the static default asset otherwise. kind is :eyecatch or
  # :map.
  def site_index_image_tag(kind, **html_options)
    attachment_name = :"index_#{kind}_image"
    attachment = site_setting_singleton.public_send(attachment_name)

    if attachment.attached?
      image_tag(attachment, html_options)
    else
      image_tag(INDEX_IMAGE_DEFAULTS.fetch(kind), html_options)
    end
  end

  # Renders the placeholder shown when a photo/video was hidden by admin
  # moderation (as opposed to never having been uploaded — see
  # #nowprinting_image_tag for that case). Falls back to the generic Now
  # Printing SVG if the admin hasn't uploaded a dedicated one.
  def removed_content_image_tag(orientation = :portrait, **html_options)
    attachment_name = orientation == :landscape ? :removed_content_landscape_image : :removed_content_portrait_image
    attachment = site_setting_singleton.public_send(attachment_name)

    if attachment.attached?
      image_tag(attachment, html_options)
    else
      image_tag("nowprinting.svg", html_options)
    end
  end

  # Shared "first visible photo, or the right placeholder" logic used by
  # every shop/cast card and gallery: shows removed_content_image_tag when
  # every uploaded photo was hidden by moderation, or nowprinting_image_tag
  # when nothing was ever uploaded.
  def photo_or_placeholder_tag(photo, removed:, orientation: :portrait, **html_options)
    if photo
      image_tag(photo, html_options)
    elsif removed
      removed_content_image_tag(orientation, **html_options)
    else
      nowprinting_image_tag(orientation, **html_options)
    end
  end

  # Shared "image, else video, else the right placeholder" logic for diary
  # entry thumbnails (shop page's 写メ日記 block and the cast page's own).
  def diary_thumb_tag(entry, **html_options)
    if entry.visible_images.any?
      image_tag(entry.visible_images.first, html_options)
    elsif entry.video.attached? && !entry.video_hidden?
      video_tag(entry.video, muted: true, preload: "metadata", **html_options)
    elsif entry.content_removed_by_moderation?
      removed_content_image_tag(:portrait, **html_options)
    else
      nowprinting_image_tag(:portrait, **html_options)
    end
  end

  YOUTUBE_ID_PATTERN = %r{(?:youtube\.com/(?:watch\?v=|embed/)|youtu\.be/)([\w-]{11})}

  # Compact, non-interactive preview for a :movie-type ShopPageBlock, used
  # where several videos are shown side by side (e.g. the TOP page's 体験動画
  # row) and a full player with controls would be too heavy. Uploaded files
  # get a muted, controls-less <video> (the browser shows its first frame);
  # YouTube URLs get the real static thumbnail image instead of an iframe;
  # any other URL falls back to the same muted <video> treatment.
  def video_thumbnail_tag(block, **html_options)
    if block.video_file.attached?
      video_tag(block.video_file, muted: true, preload: "metadata", **html_options)
    else
      url = block.settings["video_url"].to_s
      youtube_id = url[YOUTUBE_ID_PATTERN, 1]

      if youtube_id
        image_tag("https://img.youtube.com/vi/#{youtube_id}/hqdefault.jpg", html_options)
      elsif url.present?
        video_tag(url, muted: true, preload: "metadata", **html_options)
      end
    end
  end

  # Combines Shop#page_theme_style (colors, computed without a view context)
  # with the background image style, which needs url_for and so has to be
  # built here rather than on the model.
  def shop_page_theme_style(shop)
    styles = [shop.page_theme_style]
    if shop.page_background_image.attached?
      styles << "background-image: url('#{url_for(shop.page_background_image)}'); " \
        "background-size: cover; background-position: center; background-attachment: fixed;"
    end
    styles.join(" ")
  end

  private

  def site_setting_singleton
    @site_setting_singleton ||= SiteSetting.instance
  end
end
