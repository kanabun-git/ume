require "test_helper"

class ShopInquiriesControllerTest < ActionDispatch::IntegrationTest
  test "a normal inquiry submission is saved, notifies the admin by email, and shows a confirmation with the entered content" do
    assert_emails 1 do
      post shop_inquiries_path, params: { shop_inquiry: {
        shop_name: "新規店舗", contact_name: "担当太郎", email: "owner@example.com", phone: "03-1111-2222", area_note: "渋谷", message: "掲載を検討しています"
      } }
    end

    assert_response :success
    assert_equal 1, ShopInquiry.count
    assert_select "td", "新規店舗"
    assert_select "td", "担当太郎"
    assert_select "td", "渋谷"
    assert_match "掲載を検討しています", response.body
    assert_match "担当者よりご連絡いたします。今しばらくお待ちください。", response.body
    assert_select "a.btn[href=?]", root_path, text: "TOPへ戻る"
  end

  test "filling the honeypot field shows the same confirmation page without saving or emailing" do
    assert_no_emails do
      post shop_inquiries_path, params: { shop_inquiry: {
        shop_name: "spam", contact_name: "bot", email: "bot@example.com", phone: "000",
        website: "http://spam.example"
      } }
    end

    assert_response :success # looks identical to a real success
    assert_select "a.btn[href=?]", root_path, text: "TOPへ戻る"
    assert_equal 0, ShopInquiry.count
  end

  test "a missing required field re-renders the form with an error" do
    post shop_inquiries_path, params: { shop_inquiry: { shop_name: "新規店舗" } }

    assert_response :unprocessable_entity
    assert_equal 0, ShopInquiry.count
  end
end
