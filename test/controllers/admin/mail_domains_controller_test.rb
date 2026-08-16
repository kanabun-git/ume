require "test_helper"

module Admin
  class MailDomainsControllerTest < ActionDispatch::IntegrationTest
    test "a platform admin can register, edit, and delete a site" do
      sign_in create_user(role: :platform_admin)

      post admin_mail_domains_path, params: { mail_domain: { name: "サイト本体", domain: "Example.com" } }
      assert_redirected_to admin_mail_domains_path
      mail_domain = MailDomain.find_by(domain: "example.com")
      assert mail_domain.present?

      patch admin_mail_domain_path(mail_domain), params: { mail_domain: { name: "ポータルサイト" } }
      assert_equal "ポータルサイト", mail_domain.reload.name

      delete admin_mail_domain_path(mail_domain)
      assert_not MailDomain.exists?(mail_domain.id)
    end

    test "an invalid domain re-renders the management screen with the error" do
      sign_in create_user(role: :platform_admin)

      post admin_mail_domains_path, params: { mail_domain: { name: "テスト", domain: "not a domain" } }

      assert_response :unprocessable_entity
      assert_match "example.com", response.body
      assert_equal 0, MailDomain.count
    end

    test "deleting a site says how many addresses went with it" do
      sign_in create_user(role: :platform_admin)
      mail_domain = MailDomain.create!(name: "サイト本体", domain: "example.com")
      mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      delete admin_mail_domain_path(mail_domain)

      assert_match "メールアドレス1件", flash[:notice]
      assert_equal 0, MailAccount.count
    end

    test "the index lists each site with its registered addresses" do
      sign_in create_user(role: :platform_admin)
      mail_domain = MailDomain.create!(name: "キャストポータル", domain: "staff.example.net")
      mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      get admin_mail_domains_path

      assert_response :success
      assert_match "キャストポータル", response.body
      assert_match "info@staff.example.net", response.body
    end

    test "the index shows the mail client settings, including the password" do
      sign_in create_user(role: :platform_admin)
      mail_domain = MailDomain.create!(name: "サイト本体", domain: "example.com", mail_server_host: "mail.example.com")
      mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

      get admin_mail_domains_path

      assert_response :success
      assert_match "password1234", response.body
      assert_match "mail.example.com", response.body
      assert_match "993", response.body
      assert_match "587", response.body
    end

    test "the mail server host falls back to the domain itself when left blank" do
      sign_in create_user(role: :platform_admin)
      mail_domain = MailDomain.create!(name: "サイト本体", domain: "example.com")

      assert_equal "example.com", mail_domain.mail_host

      patch admin_mail_domain_path(mail_domain), params: { mail_domain: { mail_server_host: "mail.example.com" } }
      assert_equal "mail.example.com", mail_domain.reload.mail_host
    end

    test "a shop admin cannot reach mail address management" do
      sign_in create_user(role: :shop_admin, shop: create_shop)

      get admin_mail_domains_path

      assert_redirected_to root_path
    end

    test "a signed-out visitor cannot reach mail address management" do
      get admin_mail_domains_path

      assert_redirected_to new_user_session_path
    end
  end
end
