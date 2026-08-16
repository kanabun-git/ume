require_relative "boot"
require_relative "../app/middleware/maintenance_mode_middleware"
require_relative "../app/middleware/mail_admin_host_middleware"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ume
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.i18n.default_locale = :ja
    config.i18n.available_locales = [:ja, :en]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # サイトは日本国内向けのみで、常にJSTで表示・判定してよい(データベース
    # への保存は引き続きUTCのまま -- default_timezoneはRailsの既定値
    # :utcから変更していないので、Time.current等の見え方だけが変わる)。
    # これを設定していなかったため、管理画面をはじめ全画面の日時表示が
    # UTC(日本時間の9時間前)になっていた。
    config.time_zone = "Tokyo"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Shows a maintenance page for public-facing requests while the platform
    # admin has maintenance mode switched on (see MaintenanceModeMiddleware).
    config.middleware.use MaintenanceModeMiddleware

    # On the mail address management domain (MAIL_ADMIN_HOST), serve only that
    # screen -- the portal and its other back offices don't exist there.
    config.middleware.use MailAdminHostMiddleware

    # メールアドレス管理画面では、メールソフトの設定に必要なため、メールボックスの
    # パスワードを後から確認できるようにしている(app/models/mail_account.rb)。
    # データベースやバックアップに平文を残さないよう Active Record Encryption で
    # 暗号化して保存し、その鍵は他の秘密情報と同じく環境変数で渡す
    # (鍵の作り方は docs/vps_setup.md 8-4 を参照)。
    #
    # 1つの環境変数から3種類の鍵を導出しているのは、運用側が管理する秘密を
    # 1つに絞るため。開発・テストでは固定のダミー鍵で動かす。
    encryption_key = ENV["UME_ENCRYPTION_PRIMARY_KEY"].presence
    encryption_key ||= "ume-development-encryption-key" unless Rails.env.production?
    if encryption_key
      config.active_record.encryption.primary_key = encryption_key
      config.active_record.encryption.deterministic_key = "#{encryption_key}-deterministic"
      config.active_record.encryption.key_derivation_salt = "#{encryption_key}-salt"
    end

    # 本番で鍵が未設定の場合は、パスワードの保存・表示だけを行わない
    # (メールアドレスの追加・削除・送信テストはこれまで通り使えるようにする)。
    config.x.mail_password_display = encryption_key.present?

    # メールアドレス管理画面(/mailadmin)専用のBasic認証。ポータルサイトの
    # ログイン(Devise/User)とは無関係で、この画面にしか通用しない
    # 別のID・パスワード。開発・テストでは固定のダミー値、本番では環境変数が
    # 必須(未設定ならMailAdmin::BaseControllerが画面ごと503を返し、
    # 無防備な状態で公開されることはない)。
    config.x.mail_admin_http_auth_user =
      ENV["MAIL_ADMIN_HTTP_AUTH_USER"].presence || (Rails.env.production? ? nil : "admin")
    config.x.mail_admin_http_auth_password =
      ENV["MAIL_ADMIN_HTTP_AUTH_PASSWORD"].presence || (Rails.env.production? ? nil : "password1234")
  end
end
