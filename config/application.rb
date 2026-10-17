require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # 日本の時間にする(なにもしないと UTC で、夜中0時〜朝9時は「今日」が1日ずれて、支払い期限の判定がずれる)
    # データベースの中は UTC のまま保存されて、画面や Date.current のときだけ東京の時間に直る
    config.time_zone = "Tokyo"

    # 画面やエラーメッセージを日本語にする(翻訳は rails-i18n と config/locales/ja.yml)
    config.i18n.default_locale = :ja
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
