require "test_helper"

class MailAccountTest < ActiveSupport::TestCase
  setup do
    @mail_domain = MailDomain.create!(name: "サイト本体", domain: "example.com")
  end

  test "the password is stored only as a SHA-512 crypt digest" do
    account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

    assert account.password_hash.start_with?("$6$")
    assert_not_includes account.password_hash, "password1234"
    # The plaintext lives on an attr_accessor only; nothing reaches the DB.
    assert_nil MailAccount.find(account.id).password
  end

  test "the same password produces a different digest each time (salted)" do
    first = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")
    second = @mail_domain.mail_accounts.create!(local_part: "support", password: "password1234")

    assert_not_equal first.password_hash, second.password_hash
  end

  test "a password is required on create and must be long enough" do
    assert_not @mail_domain.mail_accounts.build(local_part: "info").valid?
    assert_not @mail_domain.mail_accounts.build(local_part: "info", password: "short").valid?
  end

  test "a blank password is reported once, not once per underlying column" do
    account = @mail_domain.mail_accounts.build(local_part: "info")
    account.valid?

    assert_equal ["パスワードを入力してください"], account.errors.full_messages
  end

  test "a mismatched confirmation is rejected without touching the stored digest" do
    account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")
    original_hash = account.password_hash

    assert_not account.update(password: "newpassword1234", password_confirmation: "typo-password")
    assert_equal original_hash, account.reload.password_hash
  end

  test "the password can be changed later, and left blank to keep the current one" do
    account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")
    original_hash = account.password_hash

    account.update!(local_part: "contact", password: "")
    assert_equal original_hash, account.reload.password_hash

    account.update!(password: "newpassword1234", password_confirmation: "newpassword1234")
    assert_not_equal original_hash, account.reload.password_hash
  end

  test "the local part is normalized and validated" do
    account = @mail_domain.mail_accounts.create!(local_part: " INFO@example.com ", password: "password1234")
    assert_equal "info", account.local_part

    ["", "in fo", "in/fo", ".info", "info.", "in..fo", "in\nfo", "infö"].each do |candidate|
      assert_not @mail_domain.mail_accounts.build(local_part: candidate, password: "password1234").valid?,
        "#{candidate.inspect} should be rejected"
    end
  end

  test "the same address cannot be registered twice under one site" do
    @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")
    duplicate = @mail_domain.mail_accounts.build(local_part: "info", password: "password1234")

    assert_not duplicate.valid?
  end

  test "the same local part can exist under two different sites" do
    other_domain = MailDomain.create!(name: "キャストポータル", domain: "staff.example.net")
    @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

    assert other_domain.mail_accounts.build(local_part: "info", password: "password1234").valid?
  end

  test "address and maildir_path are built from the site's domain" do
    account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

    assert_equal "info@example.com", account.address
    assert_equal "example.com/info/", account.maildir_path
  end

  test "a newly created address counts as not yet synced, and edits un-sync it" do
    account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")
    assert_not account.synced?

    account.update_columns(synced_at: Time.current)
    assert account.reload.synced?

    travel 1.second do
      account.update!(local_part: "contact")
    end
    assert_not account.reload.synced?
  end
end
