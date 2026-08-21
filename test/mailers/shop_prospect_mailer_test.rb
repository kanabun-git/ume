require "test_helper"

class ShopProspectMailerTest < ActionMailer::TestCase
  test "outreach_email links to the tracked registration URL" do
    prospect = ShopProspect.create!(name: "候補店舗", email: "prospect@example.com", listing_site_name: "○○ネット")

    mail = ShopProspectMailer.outreach_email(prospect)

    assert_equal ["prospect@example.com"], mail.to
    assert_match "掲載のご案内", mail.subject
    assert_match "候補店舗", mail.html_part.body.to_s
    assert_match "○○ネット", mail.html_part.body.to_s
    assert_match "/outreach/#{prospect.outreach_token}", mail.html_part.body.to_s
    assert_match "/outreach/#{prospect.outreach_token}", mail.text_part.body.to_s
  end
end
