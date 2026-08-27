require "test_helper"

module MailAdmin
  class MailAccountMessagesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @mail_domain = MailDomain.create!(name: "サイト本体", domain: "example.com", mail_server_host: "127.0.0.1")
      @mail_account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")
    end

    test "index shows a connection error gracefully instead of a 500" do
      get mail_admin_mail_account_messages_path(@mail_account), headers: mail_admin_auth_headers

      assert_response :success
      assert_match "受信箱に接続できませんでした", response.body
    end

    test "index reports when the password can't be read back" do
      original = Rails.application.config.x.mail_password_display
      Rails.application.config.x.mail_password_display = false

      get mail_admin_mail_account_messages_path(@mail_account), headers: mail_admin_auth_headers

      assert_response :success
      assert_match "パスワードを確認できない", response.body
    ensure
      Rails.application.config.x.mail_password_display = original
    end

    test "show redirects back to the inbox with an alert when the mail server can't be reached" do
      get mail_admin_mail_account_message_path(@mail_account, 1), headers: mail_admin_auth_headers

      assert_redirected_to mail_admin_mail_account_messages_path(@mail_account)
      assert_match "受信箱に接続できませんでした", flash[:alert]
    end

    test "a request with no credentials cannot view the inbox" do
      get mail_admin_mail_account_messages_path(@mail_account)

      assert_response :unauthorized
    end

    test "the mail domains index links to each address's inbox" do
      get mail_admin_mail_domains_path, headers: mail_admin_auth_headers

      assert_response :success
      assert_select "a[href=?]", mail_admin_mail_account_messages_path(@mail_account), text: "受信箱を見る"
    end
  end
end
