class ShopProspectMailer < ApplicationMailer
  # Sent manually, in bulk, from Admin::ShopProspectsController#send_outreach_emails
  # after the admin selects leads from the 営業先候補 list. Subject/body come
  # from OutreachEmailTemplate (admin-editable, see 営業メール文面の編集), with
  # %{name}/%{listing_site_name}/%{registration_url} filled in per prospect.
  # registration_url embeds the prospect's outreach_token so
  # ShopProspectOutreachController can tell this specific click apart from
  # ordinary site traffic.
  def outreach_email(prospect)
    template = ::OutreachEmailTemplate.instance
    vars = {
      name: prospect.name,
      listing_site_name: prospect.listing_site_name.to_s,
      registration_url: shop_prospect_outreach_url(prospect.outreach_token)
    }

    @body = template.render_body(vars)

    mail(to: prospect.email, subject: template.render_subject(vars))
  end
end
