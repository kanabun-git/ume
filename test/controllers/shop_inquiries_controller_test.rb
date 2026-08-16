require "test_helper"

class ShopInquiriesControllerTest < ActionDispatch::IntegrationTest
  test "a normal inquiry submission is saved and notifies the admin by email" do
    assert_emails 1 do
      post shop_inquiries_path, params: { shop_inquiry: {
        shop_name: "新規店舗", contact_name: "担当太郎", email: "owner@example.com", phone: "03-1111-2222"
      } }
    end

    assert_redirected_to root_path
    assert_equal 1, ShopInquiry.count
  end

  test "filling the honeypot field silently discards the submission" do
    assert_no_emails do
      post shop_inquiries_path, params: { shop_inquiry: {
        shop_name: "spam", contact_name: "bot", email: "bot@example.com", phone: "000",
        website: "http://spam.example"
      } }
    end

    assert_redirected_to root_path # looks identical to a real success
    assert_equal 0, ShopInquiry.count
  end

  test "a missing required field re-renders the form with an error" do
    post shop_inquiries_path, params: { shop_inquiry: { shop_name: "新規店舗" } }

    assert_response :unprocessable_entity
    assert_equal 0, ShopInquiry.count
  end
end
