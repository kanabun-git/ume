require "test_helper"

module Admin
  class OutreachEmailTemplatesControllerTest < ActionDispatch::IntegrationTest
    test "a platform admin can view and update the outreach email template" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      get edit_admin_outreach_email_template_path
      assert_response :success

      patch admin_outreach_email_template_path, params: {
        outreach_email_template: { subject: "新しい件名", body: "本文 %{name} %{registration_url}" }
      }

      assert_redirected_to edit_admin_outreach_email_template_path
      template = OutreachEmailTemplate.instance.reload
      assert_equal "新しい件名", template.subject
      assert_equal "本文 %{name} %{registration_url}", template.body
    end

    test "saving a body without the registration_url placeholder is rejected" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      patch admin_outreach_email_template_path, params: {
        outreach_email_template: { subject: "件名", body: "リンクなしの本文" }
      }

      assert_response :unprocessable_entity
      assert_match "%{registration_url}", response.body
    end

    test "a shop admin cannot access the outreach email template screen" do
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get edit_admin_outreach_email_template_path

      assert_redirected_to root_path
    end
  end
end
