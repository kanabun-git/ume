require "test_helper"

class OutreachEmailTemplateTest < ActiveSupport::TestCase
  test "instance creates a default template on first access" do
    template = OutreachEmailTemplate.instance

    assert_equal OutreachEmailTemplate::DEFAULT_SUBJECT, template.subject
    assert_includes template.body, "%{registration_url}"
  end

  test "instance returns the same row on repeated calls" do
    first = OutreachEmailTemplate.instance
    second = OutreachEmailTemplate.instance

    assert_equal first.id, second.id
  end

  test "requires the %{registration_url} placeholder in the body" do
    template = OutreachEmailTemplate.instance
    template.body = "リンクの差し込みがない本文です。"

    assert_not template.valid?
    assert_includes template.errors.attribute_names, :body
  end

  test "render_body substitutes known placeholders and blanks out missing ones" do
    template = OutreachEmailTemplate.new(subject: "件名", body: "%{name}様、%{listing_site_name}、%{registration_url}")

    rendered = template.render_body(name: "候補店舗", listing_site_name: "", registration_url: "https://example.com/outreach/abc")

    assert_equal "候補店舗様、、https://example.com/outreach/abc", rendered
  end

  test "render_body leaves an unrecognized placeholder blank instead of raising" do
    template = OutreachEmailTemplate.new(subject: "件名", body: "%{unknown} / %{registration_url}")

    rendered = template.render_body(registration_url: "https://example.com/outreach/abc")

    assert_equal " / https://example.com/outreach/abc", rendered
  end

  test "render_body leaves a stray literal % untouched" do
    template = OutreachEmailTemplate.new(subject: "件名", body: "割引率100%です %{registration_url}")

    rendered = template.render_body(registration_url: "https://example.com/outreach/abc")

    assert_equal "割引率100%です https://example.com/outreach/abc", rendered
  end
end
