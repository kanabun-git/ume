class CorporateInquiryMailer < ApplicationMailer
  default from: "no-reply@puremint.jp"

  def notify_admin(inquiry)
    @inquiry = inquiry

    mail(to: Corporate::Company::EMAIL, reply_to: inquiry.email, subject: "【ピュアミント】#{inquiry.subject}(#{inquiry.name}様)")
  end
end
