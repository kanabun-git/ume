require "test_helper"

class Corporate::InquiriesControllerTest < ActionDispatch::IntegrationTest
  test "a normal inquiry submission notifies the admin by email and shows a confirmation" do
    assert_emails 1 do
      post corporate_inquiries_path, params: { corporate_inquiry: {
        name: "問合太郎", company_name: "テスト株式会社", email: "taro@example.com", phone: "03-1111-2222",
        message: "取引についてご相談があります"
      } }
    end

    assert_response :success
    assert_match "お問い合わせを受け付けました", response.body
  end

  test "filling the honeypot field shows the same confirmation without emailing" do
    assert_no_emails do
      post corporate_inquiries_path, params: { corporate_inquiry: {
        name: "bot", email: "bot@example.com", message: "spam", website: "http://spam.example"
      } }
    end

    assert_response :success
    assert_match "お問い合わせを受け付けました", response.body
  end

  test "a missing required field re-renders the form with an error" do
    post corporate_inquiries_path, params: { corporate_inquiry: { name: "問合太郎" } }

    assert_response :unprocessable_entity
  end
end
