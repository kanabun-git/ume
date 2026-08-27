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

    test "reply sends an email to the inquirer and records the reply" do
      admin = create_user(role: :platform_admin)
      inquiry = ShopInquiry.create!(shop_name: "新規店舗", contact_name: "担当太郎", email: "owner@example.com", phone: "03-1111-2222")
      sign_in admin

      assert_emails 1 do
        patch reply_admin_shop_inquiry_path(inquiry), params: { reply_body: "ご連絡ありがとうございます。詳細をご案内いたします。" }
      end

      assert_redirected_to admin_shop_inquiry_path(inquiry)
      inquiry.reload
      assert_equal "ご連絡ありがとうございます。詳細をご案内いたします。", inquiry.reply_body
      assert inquiry.replied_at.present?
      assert_equal ["owner@example.com"], ActionMailer::Base.deliveries.last.to
    end

    test "reply with a blank body shows an alert and sends nothing" do
      admin = create_user(role: :platform_admin)
      inquiry = ShopInquiry.create!(shop_name: "新規店舗", contact_name: "担当太郎", email: "owner@example.com", phone: "03-1111-2222")
      sign_in admin

      assert_emails 0 do
        patch reply_admin_shop_inquiry_path(inquiry), params: { reply_body: "  " }
      end

      assert_redirected_to admin_shop_inquiry_path(inquiry)
      assert_nil inquiry.reload.replied_at
    end

    test "replying again overwrites the previous reply content and timestamp" do
      admin = create_user(role: :platform_admin)
      inquiry = ShopInquiry.create!(shop_name: "新規店舗", contact_name: "担当太郎", email: "owner@example.com", phone: "03-1111-2222")
      sign_in admin

      patch reply_admin_shop_inquiry_path(inquiry), params: { reply_body: "最初の返信" }
      first_replied_at = inquiry.reload.replied_at

      travel 1.hour do
        patch reply_admin_shop_inquiry_path(inquiry), params: { reply_body: "訂正した返信" }
      end

      inquiry.reload
      assert_equal "訂正した返信", inquiry.reply_body
      assert_not_equal first_replied_at, inquiry.replied_at
    end

    test "a shop admin cannot reply to an inquiry" do
      user = create_user(role: :shop_admin, shop: create_shop)
      inquiry = ShopInquiry.create!(shop_name: "新規店舗", contact_name: "担当太郎", email: "owner@example.com", phone: "03-1111-2222")
      sign_in user

      assert_emails 0 do
        patch reply_admin_shop_inquiry_path(inquiry), params: { reply_body: "返信" }
      end

      assert_redirected_to root_path
    end

    test "index highlights the shop name in bold red once an inquiry has gone unreplied for over a day" do
      admin = create_user(role: :platform_admin)
      overdue = ShopInquiry.create!(shop_name: "未返信で1日経過", contact_name: "担当太郎", email: "a@example.com", phone: "03-1111-2222")
      overdue.update_column(:created_at, 2.days.ago)
      fresh = ShopInquiry.create!(shop_name: "届いたばかり", contact_name: "担当次郎", email: "b@example.com", phone: "03-3333-4444")
      sign_in admin

      get admin_shop_inquiries_path

      assert_response :success
      assert_select "a.text-danger", text: "未返信で1日経過"
      assert_select "a.text-danger", text: "届いたばかり", count: 0
    end

    test "index does not highlight an inquiry that was replied to, even if over a day old" do
      admin = create_user(role: :platform_admin)
      inquiry = ShopInquiry.create!(shop_name: "返信済みで1日経過", contact_name: "担当太郎", email: "a@example.com", phone: "03-1111-2222")
      inquiry.update_columns(created_at: 2.days.ago, replied_at: 1.day.ago)
      sign_in admin

      get admin_shop_inquiries_path

      assert_response :success
      assert_select "a.text-danger", count: 0
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
