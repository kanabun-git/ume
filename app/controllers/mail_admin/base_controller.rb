module MailAdmin
  # メールアドレス管理画面(www.kanabun.tech/mailadmin)の共通土台。
  #
  # ポータルサイトの運営管理画面(/admin)とは切り離した、独立した管理画面
  # として扱う。中身は同じアプリ・同じデータベースだが、
  #
  #   * MAIL_ADMIN_HOST を設定すると、そのドメインでしか開けない
  #     (config/routes.rb。キャストポータルと同じ仕組み)
  #   * ポータルサイトのDevise/Userログインとは独立したBasic認証で保護する
  #   * 専用レイアウトで、ポータルサイトの見た目・名前は一切出さない
  #
  # ため、利用者から見ると別サイトの管理画面になる。
  class BaseController < ApplicationController
    before_action :require_http_basic_auth
    layout "mail_admin"

    private

    # ID・パスワードが1組でも未設定の環境(本番でMAIL_ADMIN_HTTP_AUTH_USER/
    # PASSWORDを設定し忘れた場合)は、認証を求めるのではなく画面ごと503にする
    # -- 「誰の入力も受け付けない」の方が「誰でも入れてしまう」より安全なため。
    def require_http_basic_auth
      configured_user = Rails.application.config.x.mail_admin_http_auth_user
      configured_password = Rails.application.config.x.mail_admin_http_auth_password

      if configured_user.blank? || configured_password.blank?
        render plain: "メールアドレス管理画面は現在利用できません(Basic認証が未設定です)。", status: :service_unavailable
        return
      end

      authenticate_or_request_with_http_basic("メールアドレス管理") do |name, password|
        ActiveSupport::SecurityUtils.secure_compare(name, configured_user) &&
          ActiveSupport::SecurityUtils.secure_compare(password, configured_password)
      end
    end
  end
end
