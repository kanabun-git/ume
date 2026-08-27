require "test_helper"

class ShopInquiryMailerTest < ActionMailer::TestCase
  test "notify_admin sends to the admin address with the inquiry details" do
    shop_inquiry = ShopInquiry.create!(
      shop_name: "テスト店舗", contact_name: "担当太郎", email: "owner@example.com",
      phone: "03-1111-2222", area_note: "渋谷", message: "掲載を検討しています"
    )

    mail = ShopInquiryMailer.notify_admin(shop_inquiry)

    assert_equal ["info@fuzoku-zero.com"], mail.to
    assert_match "テスト店舗", mail.subject
    assert_match "担当太郎", mail.html_part.body.to_s
    assert_match "掲載を検討しています", mail.html_part.body.to_s
  end
end
