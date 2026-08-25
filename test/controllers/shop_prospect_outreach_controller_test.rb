require "test_helper"

class ShopProspectOutreachControllerTest < ActionDispatch::IntegrationTest
  test "a valid token records the first click and redirects to the inquiry form" do
    prospect = ShopProspect.create!(name: "候補店舗", email: "prospect@example.com")

    get shop_prospect_outreach_path(prospect.outreach_token)

    assert_redirected_to new_shop_inquiry_path
    assert prospect.reload.outreach_link_clicked_at.present?
  end

  test "clicking twice keeps the first click time" do
    prospect = ShopProspect.create!(name: "候補店舗", email: "prospect@example.com")

    get shop_prospect_outreach_path(prospect.outreach_token)
    first_click = prospect.reload.outreach_link_clicked_at

    travel 1.hour do
      get shop_prospect_outreach_path(prospect.outreach_token)
    end

    assert_equal first_click, prospect.reload.outreach_link_clicked_at
  end

  test "an unknown token still redirects to the inquiry form instead of erroring" do
    get shop_prospect_outreach_path("does-not-exist")

    assert_redirected_to new_shop_inquiry_path
  end

  test "stays reachable during maintenance mode" do
    SiteSetting.instance.update!(maintenance_mode: true)
    prospect = ShopProspect.create!(name: "候補店舗", email: "prospect@example.com")

    get shop_prospect_outreach_path(prospect.outreach_token)

    assert_redirected_to new_shop_inquiry_path
  ensure
    SiteSetting.instance.update!(maintenance_mode: false)
  end
end
