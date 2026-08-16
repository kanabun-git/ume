require_relative "boot"
require_relative "../app/middleware/maintenance_mode_middleware"

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
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Shows a maintenance page for public-facing requests while the platform
    # admin has maintenance mode switched on (see MaintenanceModeMiddleware).
    config.middleware.use MaintenanceModeMiddleware

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
  end
end
