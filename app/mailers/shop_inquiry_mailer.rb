class ShopInquiryMailer < ApplicationMailer
  ADMIN_EMAIL = "info@fuzoku-zero.com"

  def notify_admin(shop_inquiry)
    @shop_inquiry = shop_inquiry

    mail(to: ADMIN_EMAIL, subject: "【サイト掲載のお問い合わせ】#{shop_inquiry.shop_name}")
  end
end
