require "test_helper"

module MailAdmin
  class MailDomainsControllerTest < ActionDispatch::IntegrationTest
    test "a request with the correct Basic auth credentials can register, edit, and delete a site" do
      post mail_admin_mail_domains_path, params: { mail_domain: { name: "サイト本体", domain: "Example.com" } },
        headers: mail_admin_auth_headers
      assert_redirected_to mail_admin_mail_domains_path
      mail_domain = MailDomain.find_by(domain: "example.com")
      assert mail_domain.present?

      patch mail_admin_mail_domain_path(mail_domain), params: { mail_domain: { name: "ポータルサイト" } },
        headers: mail_admin_auth_headers
      assert_equal "ポータルサイト", mail_domain.reload.name

      delete mail_admin_mail_domain_path(mail_domain), headers: mail_admin_auth_headers
      assert_not MailDomain.exists?(mail_domain.id)
    end

    test "an invalid domain re-renders the management screen with the error" do
      post mail_admin_mail_domains_path, params: { mail_domain: { name: "テスト", domain: "not a domain" } },
        headers: mail_admin_auth_headers

      assert_response :unprocessable_entity
      assert_match "example.com", response.body
      assert_equal 0, MailDomain.count
    end

    test "deleting a site says how many addresses went with it" do
      mail_domain = MailDomain.create!(name: "サイト本体", domain: "example.com")
      mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      delete mail_admin_mail_domain_path(mail_domain), headers: mail_admin_auth_headers

      assert_match "メールアドレス1件", flash[:notice]
      assert_equal 0, MailAccount.count
    end

    test "the index lists each site with its registered addresses" do
      mail_domain = MailDomain.create!(name: "キャストポータル", domain: "staff.example.net")
      mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      get mail_admin_mail_domains_path, headers: mail_admin_auth_headers

      assert_response :success
      assert_match "キャストポータル", response.body
      assert_match "info@staff.example.net", response.body
    end

    test "the index shows the mail client settings, including the password" do
      mail_domain = MailDomain.create!(name: "サイト本体", domain: "example.com", mail_server_host: "mail.example.com")
      mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      get mail_admin_mail_domains_path, headers: mail_admin_auth_headers

      assert_response :success
      assert_match "password1234", response.body
      assert_match "mail.example.com", response.body
      assert_match "993", response.body
      assert_match "587", response.body
    end

    test "the mail server host falls back to the domain itself when left blank" do
      mail_domain = MailDomain.create!(name: "サイト本体", domain: "example.com")

      assert_equal "example.com", mail_domain.mail_host

      patch mail_admin_mail_domain_path(mail_domain), params: { mail_domain: { mail_server_host: "mail.example.com" } },
        headers: mail_admin_auth_headers
      assert_equal "mail.example.com", mail_domain.reload.mail_host
    end

    test "a request with no credentials is asked to authenticate, not shown the screen" do
      get mail_admin_mail_domains_path

      assert_response :unauthorized
      assert response.headers["WWW-Authenticate"].present?
    end

    test "a request with the wrong password is refused" do
      headers = { "HTTP_AUTHORIZATION" =>
        ActionController::HttpAuthentication::Basic.encode_credentials("admin", "totally-wrong-password") }

      get mail_admin_mail_domains_path, headers: headers

      assert_response :unauthorized
    end

    test "the screen refuses to load at all when no credentials are configured on the server" do
      original_user = Rails.application.config.x.mail_admin_http_auth_user
      original_password = Rails.application.config.x.mail_admin_http_auth_password
      Rails.application.config.x.mail_admin_http_auth_user = nil
      Rails.application.config.x.mail_admin_http_auth_password = nil

      get mail_admin_mail_domains_path, headers: mail_admin_auth_headers

      assert_response :service_unavailable
    ensure
      Rails.application.config.x.mail_admin_http_auth_user = original_user
      Rails.application.config.x.mail_admin_http_auth_password = original_password
    end
  end
end
