require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "account_setup_link addresses the user and includes the reset link" do
    user = User.create!(
      email: "shop-admin-#{SecureRandom.hex(4)}@example.com",
      password: "password1234", password_confirmation: "password1234",
      name: "テストユーザー", role: :shop_admin, shop: create_shop
    )
    raw_token = user.generate_account_setup_token

    mail = UserMailer.account_setup_link(user, raw_token)

    assert_equal [user.email], mail.to
    assert_match "アカウント設定", mail.subject
    assert_match "reset_password_token=", mail.html_part.body.to_s
    assert_match "reset_password_token=", mail.text_part.body.to_s
  end
end
