require "test_helper"

class ShopProspectMailerTest < ActionMailer::TestCase
  test "outreach_email uses the default template and links to the tracked registration URL" do
    prospect = ShopProspect.create!(name: "候補店舗", email: "prospect@example.com", listing_site_name: "○○ネット")

    mail = ShopProspectMailer.outreach_email(prospect)

    assert_equal ["prospect@example.com"], mail.to
    assert_match "掲載のご案内", mail.subject
    assert_match "候補店舗", mail.html_part.body.to_s
    assert_match "/outreach/#{prospect.outreach_token}", mail.html_part.body.to_s
    assert_match "/outreach/#{prospect.outreach_token}", mail.text_part.body.to_s
  end

  test "outreach_email reflects an admin-edited template" do
    OutreachEmailTemplate.instance.update!(
      subject: "カスタム件名 %{name}",
      body: "%{name} 様 (%{listing_site_name}) こちらへ: %{registration_url}"
    )
    prospect = ShopProspect.create!(name: "候補店舗", email: "prospect@example.com", listing_site_name: "○○ネット")

    mail = ShopProspectMailer.outreach_email(prospect)

    assert_equal "カスタム件名 候補店舗", mail.subject
    assert_match "候補店舗 様 (○○ネット) こちらへ", mail.html_part.body.to_s
    assert_match "/outreach/#{prospect.outreach_token}", mail.text_part.body.to_s
  end
end
