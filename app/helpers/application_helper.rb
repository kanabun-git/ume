module ApplicationHelper
  STATUS_LABELS = {
    "Shop" => { "pending" => "承認待ち", "approved" => "承認済み", "suspended" => "停止中" },
    "Cast" => { "active" => "在籍中", "inactive" => "退店" },
    "DiaryEntry" => { "draft" => "下書き", "published" => "公開" },
    "Shift" => { "scheduled" => "予定", "cancelled" => "キャンセル" },
    "Review" => { "pending" => "承認待ち", "approved" => "承認済み", "rejected" => "却下" },
    "ShopSubscription" => { "active" => "契約中", "canceled" => "解約" },
    "ShopInquiry" => { "pending" => "未対応", "in_progress" => "対応中", "closed" => "対応済み" }
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

  # Renders the shared "Now Printing" placeholder, using the image uploaded
  # in 運営管理画面 > サイト設定 if one is set, falling back to the default
  # SVG otherwise. orientation is :portrait (3:4 spots) or :landscape.
  def nowprinting_image_tag(orientation = :portrait, **html_options)
    attachment_name = orientation == :landscape ? :nowprinting_landscape_image : :nowprinting_portrait_image
    attachment = site_setting_singleton.public_send(attachment_name)

    if attachment.attached?
      image_tag(attachment, html_options)
    else
      image_tag("nowprinting.svg", html_options)
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

  # Returns the attached image for the top gate/splash page if the admin has
  # uploaded one via 運営管理画面 > サイト設定, or nil otherwise so callers
  # can render nothing instead of a broken image. kind is :eyecatch or :map.
  def site_index_image(kind)
    attachment_name = :"index_#{kind}_image"
    attachment = site_setting_singleton.public_send(attachment_name)
    attachment if attachment.attached?
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

  private

  def site_setting_singleton
    @site_setting_singleton ||= SiteSetting.instance
  end
end
