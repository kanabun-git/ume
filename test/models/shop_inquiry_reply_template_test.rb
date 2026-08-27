require "test_helper"

class ShopInquiryReplyTemplateTest < ActiveSupport::TestCase
  test "instance creates a default template on first access" do
    template = ShopInquiryReplyTemplate.instance

    assert_equal ShopInquiryReplyTemplate::DEFAULT_BODY, template.body
  end

  test "instance returns the same row on repeated calls" do
    first = ShopInquiryReplyTemplate.instance
    second = ShopInquiryReplyTemplate.instance

    assert_equal first.id, second.id
  end

  test "requires a body" do
    template = ShopInquiryReplyTemplate.instance
    template.body = ""

    assert_not template.valid?
    assert_includes template.errors.attribute_names, :body
  end
end
