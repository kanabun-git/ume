require "test_helper"

class MailDomainTest < ActiveSupport::TestCase
  test "a domain is stored lowercase and stripped of a pasted URL or @" do
    domain = MailDomain.create!(name: "サイト本体", domain: " HTTPS://Fuzoku-Zero.com/casts ")

    assert_equal "fuzoku-zero.com", domain.domain
  end

  test "a leading @ and a trailing dot are dropped" do
    assert_equal "example.com", MailDomain.create!(name: "テスト", domain: "@example.com.").domain
  end

  test "a domain without a dot is rejected" do
    domain = MailDomain.new(name: "テスト", domain: "localhost")

    assert_not domain.valid?
    assert domain.errors.of_kind?(:domain, :invalid)
  end

  test "a domain with characters that would break the mail server maps is rejected" do
    ["exa mple.com", "example.com\nevil.com", "exa/mple.com", "-example.com", "example..com"].each do |candidate|
      assert_not MailDomain.new(name: "テスト", domain: candidate).valid?, "#{candidate} should be rejected"
    end
  end

  test "the same domain cannot be registered twice, whatever the casing" do
    MailDomain.create!(name: "サイト本体", domain: "example.com")
    duplicate = MailDomain.new(name: "別サイト", domain: "EXAMPLE.com")

    assert_not duplicate.valid?
    assert_includes duplicate.errors.full_messages.join, "既に登録されています"
  end

  test "deleting a site deletes the addresses registered under it" do
    domain = MailDomain.create!(name: "サイト本体", domain: "example.com")
    domain.mail_accounts.create!(local_part: "info", password: "password1234")

    assert_difference "MailAccount.count", -1 do
      domain.destroy
    end
  end
end
