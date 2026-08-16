module MailAdmin
  # メールアドレス管理画面(www.kanabun.tech/mailadmin)の共通土台。
  #
  # ポータルサイトの運営管理画面(/admin)とは切り離した、独立した管理画面
  # として扱う。中身は同じアプリ・同じデータベースだが、
  #
  #   * MAIL_ADMIN_HOST を設定すると、そのドメインでしか開けない
  #     (config/routes.rb。キャストポータルと同じ仕組み)
  #   * 専用レイアウトで、ポータルサイトの見た目・名前は一切出さない
  #
  # ため、利用者から見ると別サイトの管理画面になる。
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_platform_admin_role!
    layout "mail_admin"

    private

    def require_platform_admin_role!
      return if current_user.platform_admin?

      flash[:alert] = "この画面を利用する権限がありません。"
      redirect_to root_path
    end
  end
end
