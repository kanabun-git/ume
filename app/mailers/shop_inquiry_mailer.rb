class ShopInquiryMailer < ApplicationMailer
  ADMIN_EMAIL = "info@fuzoku-zero.com"

  def notify_admin(shop_inquiry)
    @shop_inquiry = shop_inquiry

    mail(to: ADMIN_EMAIL, subject: "【サイト掲載のお問い合わせ】#{shop_inquiry.shop_name}")
  end

  # Sent from Admin::ShopInquiriesController#reply to the inquirer's own
  # address -- the only way this app contacts them back, since inquiries
  # aren't shown anywhere public (unlike a review's shop_reply).
  def reply_to_inquirer(shop_inquiry)
    @shop_inquiry = shop_inquiry
    @body = shop_inquiry.reply_body

    mail(to: shop_inquiry.email, subject: "【風俗Zero】お問い合わせへの返信")
  end
end
