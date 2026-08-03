require "test_helper"

class ReviewReplyTemplateTest < ActiveSupport::TestCase
  test "requires a title and body" do
    template = create_shop.review_reply_templates.build

    assert_not template.valid?
    assert_includes template.errors.attribute_names, :title
    assert_includes template.errors.attribute_names, :body
  end

  test "a valid template belongs to a shop" do
    shop = create_shop
    template = shop.review_reply_templates.create!(title: "お礼", body: "ご来店ありがとうございました。")

    assert template.persisted?
    assert_equal shop, template.shop
  end
end
