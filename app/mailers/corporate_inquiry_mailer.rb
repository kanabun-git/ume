class CorporateInquiryMailer < ApplicationMailer
  default from: "no-reply@puremint.jp"

  def notify_admin(inquiry)
    @inquiry = inquiry

    mail(to: Corporate::Company::EMAIL, reply_to: inquiry.email, subject: "【ピュアミント】お問い合わせ(#{inquiry.name}様)")
  end
end
