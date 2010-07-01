# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/app/middlewares #{RAILS_ROOT}/app/models/widgets )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem "mongo", :version => "1.0.3"
  config.gem "bson_ext", :version => "1.0.1", :lib => "bson"
  config.gem "rdiscount", :version => "1.6.3.1"
  config.gem "jnunemaker-validatable", :version => "1.8.4", :lib => "validatable"
  config.gem "mongo_mapper", :version => "0.8.2", :source => "http://gemcutter.org"
  config.gem "compass", :version => "0.10.0.rc4", :lib => "compass", :source => "http://gemcutter.org"
  config.gem "fancy-buttons", :version => "0.5.1", :source => "http://gemcutter.org"
  config.gem "compass-colors", :version => "0.3.1", :source => "http://gemcutter.org"
  config.gem "ruby-stemmer", :version => ">=0.5.3", :lib => "lingua/stemmer"
  config.gem "mongomapper_ext", :version => "0.4.0", :source => "http://gemcutter.org"
  config.gem "geoip"
  config.gem "whatlanguage", :version => "1.0.0"
  config.gem "uuidtools", :version => "2.1.1"
  config.gem "magent", :version => "0.4"
  config.gem "differ", :version => "0.1.1"
  config.gem 'super_exception_notifier', :version => '~> 2.0.0', :lib => 'exception_notifier'
  config.gem "warden", :version => "0.10.7"
  config.gem "dcu-devise", :version => "1.0.7", :lib => "devise"
  config.gem "twitter-text", :version => "1.1.1"
  config.gem "oauth2", :version => "0.0.8"
  config.gem "twitter_oauth", :version => "0.3.6"
  config.gem "sanitize", :version => "1.2.1"

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]
  config.frameworks -= [ :active_record]
  config.action_mailer.delivery_method = :sendmail
  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  config.i18n.load_path += Dir[File.join(RAILS_ROOT, 'config', 'locales', '**', '*.{rb,yml}')]
  config.i18n.default_locale = :en
  config.action_controller.use_accept_header = false
  # middlewares
  config.middleware.use "DynamicDomain"
end

require "smtp_tls"
