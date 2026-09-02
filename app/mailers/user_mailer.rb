class UserMailer < ApplicationMailer
  # Sent manually by a platform admin from the "アカウント案内を発行する" screen
  # (see Admin::UsersController#send_account_setup_email), as an alternative
  # to copy/pasting the link by hand (see #issue_account_setup_link).
  def account_setup_link(user, raw_token)
    @user = user
    @account_setup_url = edit_user_password_url(reset_password_token: raw_token)

    mail(to: @user.email, subject: "【FuzokuZero】アカウント設定のご案内")
  end
end
