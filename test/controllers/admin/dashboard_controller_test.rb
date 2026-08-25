require "test_helper"

module Admin
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    test "shows the count of active (non-archived) shop inquiries" do
      admin = create_user(role: :platform_admin)
      ShopInquiry.create!(shop_name: "現役店舗", contact_name: "担当者", email: "a@example.com", phone: "03-0000-0000")
      ShopInquiry.create!(shop_name: "アーカイブ店舗", contact_name: "担当者", email: "b@example.com", phone: "03-0000-0001", archived_at: Time.current)
      sign_in admin

      get admin_root_path

      assert_response :success
      assert_select ".card", text: /1\s*掲載のお問い合わせ/
    end
  end
end
