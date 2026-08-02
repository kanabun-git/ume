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

  # Renders the shared "Now Printing" placeholder, using the image uploaded
  # in 運営管理画面 > サイト設定 if one is set, falling back to the default
  # SVG otherwise. orientation is :portrait (3:4 spots) or :landscape.
  def nowprinting_image_tag(orientation = :portrait, **html_options)
    attachment_name = orientation == :landscape ? :nowprinting_landscape_image : :nowprinting_portrait_image
    attachment = (@nowprinting_site_setting ||= SiteSetting.instance).public_send(attachment_name)

    if attachment.attached?
      image_tag(attachment, html_options)
    else
      image_tag("nowprinting.svg", html_options)
    end
  end
end
