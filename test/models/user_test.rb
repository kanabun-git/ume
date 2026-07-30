require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "generate_account_setup_token issues a token that validates via Devise's password reset" do
    user = User.create!(name: "テスト管理者", email: "shop-admin@example.com", password: "password1234", password_confirmation: "password1234", role: :shop_admin, shop: create_shop)

    raw_token = user.generate_account_setup_token

    assert user.reset_password_token.present?, "should persist an encrypted token"
    found = User.with_reset_password_token(raw_token)
    assert_equal user, found
    assert found.reset_password_period_valid?
  end

  test "generate_account_setup_token does not send any email" do
    user = User.create!(name: "テスト管理者", email: "shop-admin2@example.com", password: "password1234", password_confirmation: "password1234", role: :shop_admin, shop: create_shop)

    assert_no_emails do
      user.generate_account_setup_token
    end
  end
end
