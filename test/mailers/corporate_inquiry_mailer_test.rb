require "test_helper"

class CorporateInquiryMailerTest < ActionMailer::TestCase
  test "notify_admin sends to the company address with the inquiry details, replyable to the sender" do
    inquiry = Corporate::Inquiry.new(
      subject: "やどかりペンションお問い合わせ", name: "問合太郎", company_name: "テスト株式会社",
      email: "taro@example.com", phone: "03-1111-2222", message: "取引についてご相談があります"
    )

    mail = CorporateInquiryMailer.notify_admin(inquiry)

    assert_equal [Corporate::Company::EMAIL], mail.to
    assert_equal ["taro@example.com"], mail.reply_to
    assert_match "やどかりペンションお問い合わせ", mail.subject
    assert_match "問合太郎", mail.subject
    assert_match "やどかりペンションお問い合わせ", mail.html_part.body.to_s
    assert_match "テスト株式会社", mail.html_part.body.to_s
    assert_match "取引についてご相談があります", mail.html_part.body.to_s
  end
end
