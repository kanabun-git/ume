require "test_helper"

class ShopInquiryTest < ActiveSupport::TestCase
  test "valid with all required fields" do
    inquiry = ShopInquiry.new(shop_name: "テスト店舗", contact_name: "担当者", email: "a@example.com", phone: "03-0000-0000")

    assert inquiry.valid?
  end

  test "invalid without shop_name, contact_name, email, or phone" do
    inquiry = ShopInquiry.new

    assert_not inquiry.valid?
    assert_includes inquiry.errors.attribute_names, :shop_name
    assert_includes inquiry.errors.attribute_names, :contact_name
    assert_includes inquiry.errors.attribute_names, :email
    assert_includes inquiry.errors.attribute_names, :phone
  end

  test "defaults to pending status" do
    inquiry = ShopInquiry.create!(shop_name: "テスト店舗", contact_name: "担当者", email: "a@example.com", phone: "03-0000-0000")

    assert inquiry.pending?
  end

  test "defaults to not archived, and .active/.archived scopes split on archived_at" do
    active = ShopInquiry.create!(shop_name: "現役店舗", contact_name: "担当者", email: "a@example.com", phone: "03-0000-0000")
    archived = ShopInquiry.create!(shop_name: "アーカイブ店舗", contact_name: "担当者", email: "b@example.com", phone: "03-0000-0001", archived_at: Time.current)

    assert_not active.archived?
    assert archived.archived?
    assert_includes ShopInquiry.active, active
    assert_not_includes ShopInquiry.active, archived
    assert_includes ShopInquiry.archived, archived
    assert_not_includes ShopInquiry.archived, active
  end

  test "reply_overdue? is true only once unreplied and over a day old" do
    fresh_unreplied = ShopInquiry.create!(shop_name: "新規", contact_name: "担当者", email: "a@example.com", phone: "03-0000-0000")
    old_unreplied = ShopInquiry.create!(shop_name: "古い未返信", contact_name: "担当者", email: "b@example.com", phone: "03-0000-0001")
    old_unreplied.update_column(:created_at, 2.days.ago)
    old_replied = ShopInquiry.create!(shop_name: "古い返信済み", contact_name: "担当者", email: "c@example.com", phone: "03-0000-0002")
    old_replied.update_columns(created_at: 2.days.ago, replied_at: 1.hour.ago)

    assert_not fresh_unreplied.reply_overdue?
    assert old_unreplied.reply_overdue?
    assert_not old_replied.reply_overdue?
  end
end
