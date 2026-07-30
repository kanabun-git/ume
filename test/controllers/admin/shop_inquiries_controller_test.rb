require "test_helper"

module Admin
  class ShopInquiriesControllerTest < ActionDispatch::IntegrationTest
    test "platform admin can view and update the status of an inquiry" do
      admin = create_user(role: :platform_admin)
      inquiry = ShopInquiry.create!(shop_name: "新規店舗", contact_name: "担当太郎", email: "owner@example.com", phone: "03-1111-2222")
      sign_in admin

      get admin_shop_inquiry_path(inquiry)
      assert_response :success

      patch update_status_admin_shop_inquiry_path(inquiry), params: { status: "in_progress" }

      assert_redirected_to admin_shop_inquiries_path
      assert inquiry.reload.in_progress?
    end

    test "a shop admin cannot view inquiries" do
      shop_admin = create_user(role: :shop_admin, shop: create_shop)
      inquiry = ShopInquiry.create!(shop_name: "新規店舗", contact_name: "担当太郎", email: "owner@example.com", phone: "03-1111-2222")
      sign_in shop_admin

      get admin_shop_inquiry_path(inquiry)

      assert_redirected_to root_path
    end

    test "an invalid status value is rejected instead of raising" do
      admin = create_user(role: :platform_admin)
      inquiry = ShopInquiry.create!(shop_name: "新規店舗", contact_name: "担当太郎", email: "owner@example.com", phone: "03-1111-2222")
      sign_in admin

      patch update_status_admin_shop_inquiry_path(inquiry), params: { status: "bogus" }

      assert_redirected_to admin_shop_inquiries_path
      assert inquiry.reload.pending?
    end
  end
end
