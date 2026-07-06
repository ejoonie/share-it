require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SpApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

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
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # SES SMTP — 환경변수가 있을 때만 활성화 (dev는 .env, prod는 서버 환경변수)
    if ENV["SMTP_USERNAME"].present?
      config.action_mailer.delivery_method = :smtp
      config.action_mailer.smtp_settings = {
        address: ENV["SMTP_ENDPOINT"],
        port: ENV["SMTP_PORT"],
        user_name: ENV["SMTP_USERNAME"],
        password: ENV["SMTP_PASSWORD"],
        authentication: :login,
        enable_starttls_auto: true,
      }
    end
  end
end
