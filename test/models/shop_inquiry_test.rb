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
end
