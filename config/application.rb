# coding: utf-8
require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"
require "rails/test_unit/railtie"
require 'sprockets/railtie'


if defined?(Bundler)
  Bundler.require *Rails.groups(:assets => %w(production development test))
end

module MakeSlide
  class Application < Rails::Application
    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/uploaders)
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += %W(#{config.root}/app/grape)
    config.autoload_paths += %W(#{config.root}workers)

    config.time_zone = 'Beijing'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = "zh-CN"

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirm, :token, :private_token]

    config.mongoid.include_root_in_json = false

    config.assets.enabled = true
    config.assets.version = '1.0'

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_girl, :dir => "spec/factories"
    end
    config.action_view.sanitized_allowed_attributes = %w{target}
    config.to_prepare {
      Devise::Mailer.layout "mailer"
    }

    # config.assets.paths << Rails.root.join("app", "assets", "fonts")
    # config.assets.paths << Rails.root.join("app", "assets", "sound")
    config.assets.precompile += %w(application.css app.js applazy.js slides.js front.js front.css cpanel.css)
    # config.assets.precompile << /\.(?:svg|eot|woff|ttf|mp3)$/
    # config.assets.precompile << /dropzone.+\.png$/
    config.middleware.use Rack::Cors do
      allow do
        origins '*'
        resource '/api/*', headers: :any, methods: [:get, :post, :put, :delete, :destroy]
      end
    end
  end
end

require "markdown"

I18n.locale = 'zh-CN'



