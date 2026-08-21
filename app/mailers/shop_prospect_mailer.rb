class ShopProspectMailer < ApplicationMailer
  # Sent manually, in bulk, from Admin::ShopProspectsController#send_outreach_emails
  # after the admin selects leads from the 営業先候補 list. The link embeds
  # the prospect's outreach_token so ShopProspectOutreachController can tell
  # this specific click apart from ordinary site traffic.
  def outreach_email(prospect)
    @prospect = prospect
    @registration_url = shop_prospect_outreach_url(prospect.outreach_token)

    mail(to: prospect.email, subject: "【FuzokuZero】掲載のご案内")
  end
end
