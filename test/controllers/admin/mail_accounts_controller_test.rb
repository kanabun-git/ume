require "test_helper"

module Admin
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

    test "a platform admin can add an address to a site" do
      sign_in create_user(role: :platform_admin)

      post admin_mail_domain_mail_accounts_path(@mail_domain), params: {
        mail_account: { local_part: "info", password: "password1234", password_confirmation: "password1234" }
      }

      assert_redirected_to admin_mail_domains_path
      account = MailAccount.find_by(local_part: "info")
      assert_equal @mail_domain, account.mail_domain
      assert_match "info@example.com を追加しました。", flash[:notice]
    end

    test "an invalid address re-renders the management screen without saving" do
      sign_in create_user(role: :platform_admin)

      post admin_mail_domain_mail_accounts_path(@mail_domain), params: {
        mail_account: { local_part: "in valid", password: "short" }
      }

      assert_response :unprocessable_entity
      assert_equal 0, MailAccount.count
      assert_match "メールアドレス管理", response.body
    end

    test "a platform admin can change an address's password and read the new one back" do
      sign_in create_user(role: :platform_admin)
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      patch admin_mail_account_path(account), params: {
        mail_account: { password: "newpassword1234", password_confirmation: "newpassword1234" }
      }

      assert_redirected_to admin_mail_domains_path
      assert_match "パスワードを変更しました。", flash[:notice]
      assert_equal "newpassword1234", account.reload.displayable_password
    end

    test "a password change with a mismatched confirmation keeps the old password" do
      sign_in create_user(role: :platform_admin)
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      patch admin_mail_account_path(account), params: {
        mail_account: { password: "newpassword1234", password_confirmation: "typo-password" }
      }

      assert_response :unprocessable_entity
      assert_equal "password1234", account.reload.displayable_password
    end

    test "submitting an empty password change is refused instead of silently doing nothing" do
      sign_in create_user(role: :platform_admin)
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      patch admin_mail_account_path(account), params: { mail_account: { password: "" } }

      assert_redirected_to admin_mail_domains_path
      assert_match "新しいパスワードを入力してください", flash[:alert]
      assert_equal "password1234", account.reload.displayable_password
    end

    test "the address cannot be renamed through the password change form" do
      sign_in create_user(role: :platform_admin)
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      patch admin_mail_account_path(account), params: {
        mail_account: { local_part: "hijacked", password: "newpassword1234", password_confirmation: "newpassword1234" }
      }

      assert_equal "info", account.reload.local_part
    end

    test "a shop admin cannot change a mailbox password" do
      sign_in create_user(role: :shop_admin, shop: create_shop)
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      patch admin_mail_account_path(account), params: {
        mail_account: { password: "newpassword1234", password_confirmation: "newpassword1234" }
      }

      assert_redirected_to root_path
      assert_equal "password1234", account.reload.displayable_password
    end

    test "a platform admin can delete an address" do
      sign_in create_user(role: :platform_admin)
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      delete admin_mail_account_path(account)

      assert_redirected_to admin_mail_domains_path
      assert_not MailAccount.exists?(account.id)
      assert_match "info@example.com を削除しました。", flash[:notice]
    end

    test "a test send delivers one mail from the address and records the result" do
      sign_in create_user(role: :platform_admin)
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      assert_emails 1 do
        post test_delivery_admin_mail_account_path(account), params: { to: "operator@example.org" }
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
      sign_in create_user(role: :platform_admin)
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      assert_no_emails do
        post test_delivery_admin_mail_account_path(account), params: { to: "not-an-address" }
      end

      assert_redirected_to admin_mail_domains_path
      assert_match "正しく入力してください", flash[:alert]
      assert_nil account.reload.last_test_sent_at
    end

    test "a delivery failure is reported on the screen instead of raising" do
      sign_in create_user(role: :platform_admin)
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      with_delivery_method(:rejecting) do
        post test_delivery_admin_mail_account_path(account), params: { to: "operator@example.org" }
      end

      assert_redirected_to admin_mail_domains_path
      assert_match "550 sender rejected", flash[:alert]
      account.reload
      assert_not account.last_test_succeeded?
      assert_match "550 sender rejected", account.last_test_error
    end

    test "a platform admin can re-run the mail server sync by hand" do
      sign_in create_user(role: :platform_admin)

      post sync_admin_mail_accounts_path

      assert_redirected_to admin_mail_domains_path
      assert flash[:notice].present?
    end

    test "a shop admin can neither add nor delete addresses" do
      sign_in create_user(role: :shop_admin, shop: create_shop)
      account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      post admin_mail_domain_mail_accounts_path(@mail_domain), params: {
        mail_account: { local_part: "hijack", password: "password1234" }
      }
      assert_redirected_to root_path

      delete admin_mail_account_path(account)
      assert_redirected_to root_path
      assert MailAccount.exists?(account.id)
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
