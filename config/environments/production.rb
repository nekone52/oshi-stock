require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on Amazon S3 (see config/storage.yml for options).
  # Render は再デプロイでディスクが消えるため、画像は S3 に保存する
  config.active_storage.service = :amazon

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # MVP ではデータベースを1つにするため、キャッシュとジョブはデータベースを使わない仕組みにする
  # (Render の無料の PostgreSQL は1つだけ。重いジョブが必要になったら solid_cache / solid_queue に戻す)
  config.cache_store = :memory_store
  config.active_job.queue_adapter = :async

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates.
  # メールはブラウザの外から届くので、リンクの住所を教えておく(パスワード再設定のリンクが本番の画面にとぶように)
  # 合言葉(トークン)入りのリンクなので、最初から鍵つきの https にする
  # 【自分の言葉】メールのリンクを、推しストックの本番(https)へ行くようにする
  config.action_mailer.default_url_options = { host: "oshi-stock.onrender.com", protocol: "https" }

  # メールの配達方法(delivery_method)。Render の無料プランは SMTP がふさがれているので、HTTPS で送れる Resend を使う
  # 【自分の言葉】配達!メールを Resend で届ける!
  config.action_mailer.delivery_method = :resend

  # Specify outgoing SMTP server. Remember to add smtp/* credentials via bin/rails credentials:edit.
  # config.action_mailer.smtp_settings = {
  #   user_name: Rails.application.credentials.dig(:smtp, :user_name),
  #   password: Rails.application.credentials.dig(:smtp, :password),
  #   address: "smtp.example.com",
  #   port: 587,
  #   authentication: :plain
  # }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # 本番は Render の URL からのアクセスだけ受け付ける(独自ドメインを使うときはここに足す)
  config.hosts = [ "oshi-stock.onrender.com" ]

  # Skip DNS rebinding protection for the default health check endpoint.
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
