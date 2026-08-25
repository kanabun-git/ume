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

    test "index excludes archived inquiries and shows only active ones" do
      admin = create_user(role: :platform_admin)
      active = ShopInquiry.create!(shop_name: "現役店舗", contact_name: "担当太郎", email: "a@example.com", phone: "03-1111-2222")
      archived = ShopInquiry.create!(shop_name: "アーカイブ店舗", contact_name: "担当次郎", email: "b@example.com", phone: "03-3333-4444", archived_at: Time.current)
      sign_in admin

      get admin_shop_inquiries_path

      assert_response :success
      assert_match "現役店舗", response.body
      assert_no_match "アーカイブ店舗", response.body
    end

    test "archive moves an inquiry out of the main index without deleting it" do
      admin = create_user(role: :platform_admin)
      inquiry = ShopInquiry.create!(shop_name: "新規店舗", contact_name: "担当太郎", email: "owner@example.com", phone: "03-1111-2222")
      sign_in admin

      patch archive_admin_shop_inquiry_path(inquiry)

      assert_redirected_to admin_shop_inquiries_path
      assert inquiry.reload.archived?
      assert ShopInquiry.exists?(inquiry.id)
    end

    test "archived lists only archived inquiries, and unarchive returns one to the main index" do
      admin = create_user(role: :platform_admin)
      inquiry = ShopInquiry.create!(shop_name: "アーカイブ店舗", contact_name: "担当太郎", email: "owner@example.com", phone: "03-1111-2222", archived_at: Time.current)
      sign_in admin

      get archived_admin_shop_inquiries_path
      assert_response :success
      assert_match "アーカイブ店舗", response.body

      patch unarchive_admin_shop_inquiry_path(inquiry)

      assert_redirected_to archived_admin_shop_inquiries_path
      assert_not inquiry.reload.archived?
    end

    test "destroy permanently deletes an archived inquiry" do
      admin = create_user(role: :platform_admin)
      inquiry = ShopInquiry.create!(shop_name: "アーカイブ店舗", contact_name: "担当太郎", email: "owner@example.com", phone: "03-1111-2222", archived_at: Time.current)
      sign_in admin

      delete admin_shop_inquiry_path(inquiry)

      assert_redirected_to archived_admin_shop_inquiries_path
      assert_not ShopInquiry.exists?(inquiry.id)
    end

    test "destroy refuses to delete an inquiry that is not archived yet" do
      admin = create_user(role: :platform_admin)
      inquiry = ShopInquiry.create!(shop_name: "新規店舗", contact_name: "担当太郎", email: "owner@example.com", phone: "03-1111-2222")
      sign_in admin

      delete admin_shop_inquiry_path(inquiry)

      assert_redirected_to admin_shop_inquiries_path
      assert ShopInquiry.exists?(inquiry.id)
    end

    test "a shop admin cannot destroy an inquiry" do
      shop_admin = create_user(role: :shop_admin, shop: create_shop)
      inquiry = ShopInquiry.create!(shop_name: "アーカイブ店舗", contact_name: "担当太郎", email: "owner@example.com", phone: "03-1111-2222", archived_at: Time.current)
      sign_in shop_admin

      delete admin_shop_inquiry_path(inquiry)

      assert_redirected_to root_path
      assert ShopInquiry.exists?(inquiry.id)
    end

    test "a shop admin cannot archive an inquiry" do
      shop_admin = create_user(role: :shop_admin, shop: create_shop)
      inquiry = ShopInquiry.create!(shop_name: "新規店舗", contact_name: "担当太郎", email: "owner@example.com", phone: "03-1111-2222")
      sign_in shop_admin

      patch archive_admin_shop_inquiry_path(inquiry)

      assert_redirected_to root_path
      assert_not inquiry.reload.archived?
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
