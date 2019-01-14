require_relative 'boot'

require "active_model/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ilscatcher4
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    config.action_dispatch.default_headers.merge!(
      'Cache-Control' => 'no-store, no-cache'
    )

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    Settings.add_source!("#{Rails.root}/config/settings/system/" + ENV['SYSTEM_NAME'] + ".yml")
    Settings.add_source!("#{Rails.root}/config/settings/" + ENV['CONFIG_FILE'] + '.yml')
    Settings.reload!
  end
end
