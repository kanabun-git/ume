require "test_helper"

module MailAdmin
  class MailAccountsControllerTest < ActionDispatch::IntegrationTest
    # Stands in for a mail server that rejects the message, so the test
    # exercises the real "deliver_now raised" path rather than a stub.
    class RejectingDeliveryMethod
      def initialize(settings = {}); end

      def deliver!(_mail)
        raise Net::SMTPFatalError, "550 sender rejected"
      end
    end
    ActionMailer::Base.add_delivery_method(:rejecting, RejectingDeliveryMethod)

    setup do
      @mail_domain = MailDomain.create!(name: "サイト本体", domain: "example.com")
    end

    test "a request with the correct Basic auth credentials can add an address to a site" do
      post mail_admin_mail_domain_mail_accounts_path(@mail_domain), params: {
        mail_account: { local_part: "info", password: "password1234", password_confirmation: "password1234" }
      }, headers: mail_admin_auth_headers

      assert_redirected_to mail_admin_mail_domains_path
      account = MailAccount.find_by(local_part: "info")
      assert_equal @mail_domain, account.mail_domain
      assert_match "info@example.com を追加しました。", flash[:notice]
    end

    test "an invalid address re-renders the management screen without saving" do
      post mail_admin_mail_domain_mail_accounts_path(@mail_domain), params: {
        mail_account: { local_part: "in valid", password: "short" }
      }, headers: mail_admin_auth_headers

      assert_response :unprocessable_entity
      assert_equal 0, MailAccount.count
      assert_match "メールアドレス管理", response.body
    end

    test "a request with no credentials cannot add an address" do
      post mail_admin_mail_domain_mail_accounts_path(@mail_domain), params: {
        mail_account: { local_part: "hijack", password: "password1234" }
      }

      assert_response :unauthorized
      assert_equal 0, MailAccount.count
    end

    test "the password can be changed and read back" do
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      patch mail_admin_mail_account_path(account), params: {
        mail_account: { password: "newpassword1234", password_confirmation: "newpassword1234" }
      }, headers: mail_admin_auth_headers

      assert_redirected_to mail_admin_mail_domains_path
      assert_match "パスワードを変更しました。", flash[:notice]
      assert_equal "newpassword1234", account.reload.displayable_password
    end

    test "a password change with a mismatched confirmation keeps the old password" do
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      patch mail_admin_mail_account_path(account), params: {
        mail_account: { password: "newpassword1234", password_confirmation: "typo-password" }
      }, headers: mail_admin_auth_headers

      assert_response :unprocessable_entity
      assert_equal "password1234", account.reload.displayable_password
    end

    test "submitting an empty password change is refused instead of silently doing nothing" do
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      patch mail_admin_mail_account_path(account), params: { mail_account: { password: "" } },
        headers: mail_admin_auth_headers

      assert_redirected_to mail_admin_mail_domains_path
      assert_match "新しいパスワードを入力してください", flash[:alert]
      assert_equal "password1234", account.reload.displayable_password
    end

    test "the address cannot be renamed through the password change form" do
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      patch mail_admin_mail_account_path(account), params: {
        mail_account: { local_part: "hijacked", password: "newpassword1234", password_confirmation: "newpassword1234" }
      }, headers: mail_admin_auth_headers

      assert_equal "info", account.reload.local_part
    end

    test "a request with no credentials cannot change a password" do
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      patch mail_admin_mail_account_path(account), params: {
        mail_account: { password: "newpassword1234", password_confirmation: "newpassword1234" }
      }

      assert_response :unauthorized
      assert_equal "password1234", account.reload.displayable_password
    end

    test "an address can be deleted" do
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      delete mail_admin_mail_account_path(account), headers: mail_admin_auth_headers

      assert_redirected_to mail_admin_mail_domains_path
      assert_not MailAccount.exists?(account.id)
      assert_match "info@example.com を削除しました。", flash[:notice]
    end

    test "a request with no credentials cannot delete an address" do
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      delete mail_admin_mail_account_path(account)

      assert_response :unauthorized
      assert MailAccount.exists?(account.id)
    end

    test "a test send delivers one mail from the address and records the result" do
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      assert_emails 1 do
        post test_delivery_mail_admin_mail_account_path(account), params: { to: "operator@example.org" },
          headers: mail_admin_auth_headers
      end

      mail = ActionMailer::Base.deliveries.last
      assert_equal ["info@example.com"], mail.from
      assert_equal ["operator@example.org"], mail.to
      assert_match "送信テスト", mail.subject

      account.reload
      assert account.last_test_succeeded?
      assert_equal "operator@example.org", account.last_test_to
      assert account.last_test_sent_at.present?
    end

    test "a test send to a malformed address is refused before anything is delivered" do
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      assert_no_emails do
        post test_delivery_mail_admin_mail_account_path(account), params: { to: "not-an-address" },
          headers: mail_admin_auth_headers
      end

      assert_redirected_to mail_admin_mail_domains_path
      assert_match "正しく入力してください", flash[:alert]
      assert_nil account.reload.last_test_sent_at
    end

    test "a delivery failure is reported on the screen instead of raising" do
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      with_delivery_method(:rejecting) do
        post test_delivery_mail_admin_mail_account_path(account), params: { to: "operator@example.org" },
          headers: mail_admin_auth_headers
      end

      assert_redirected_to mail_admin_mail_domains_path
      assert_match "550 sender rejected", flash[:alert]
      account.reload
      assert_not account.last_test_succeeded?
      assert_match "550 sender rejected", account.last_test_error
    end

    test "a round-trip test with no reachable mail server fails gracefully and records why" do
      @mail_domain.update!(mail_server_host: "127.0.0.1") # fails fast (connection refused), no real network needed
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      assert_emails 1 do
        post round_trip_test_mail_admin_mail_account_path(account), headers: mail_admin_auth_headers
      end

      assert_redirected_to mail_admin_mail_domains_path
      account.reload
      assert_not account.last_round_trip_succeeded?
      assert account.last_round_trip_tested_at.present?
      assert account.last_round_trip_error.present?
    end

    test "a round-trip test reports that it cannot run without a readable password" do
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")
      original = Rails.application.config.x.mail_password_display
      Rails.application.config.x.mail_password_display = false

      assert_no_emails do
        post round_trip_test_mail_admin_mail_account_path(account), headers: mail_admin_auth_headers
      end

      account.reload
      assert_not account.last_round_trip_succeeded?
      assert_match "パスワードを確認できない", account.last_round_trip_error
    ensure
      Rails.application.config.x.mail_password_display = original
    end

    test "a request with no credentials cannot run a round-trip test" do
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      post round_trip_test_mail_admin_mail_account_path(account)

      assert_response :unauthorized
      assert_nil account.reload.last_round_trip_tested_at
    end

    test "the mail server sync can be re-run by hand" do
      post sync_mail_admin_mail_accounts_path, headers: mail_admin_auth_headers

      assert_redirected_to mail_admin_mail_domains_path
      assert flash[:notice].present?
    end

    test "a request with no credentials cannot trigger a sync" do
      post sync_mail_admin_mail_accounts_path

      assert_response :unauthorized
    end

    private

    def with_delivery_method(method)
      original = ActionMailer::Base.delivery_method
      ActionMailer::Base.delivery_method = method
      yield
    ensure
      ActionMailer::Base.delivery_method = original
    end
  end
end
