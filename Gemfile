source 'https://rubygems.org'

RAILS_VERSION = '~> 4.1.8'

send :ruby, ENV['GEMFILE_RUBY_VERSION'] if ENV['GEMFILE_RUBY_VERSION']

gem 'actionmailer', RAILS_VERSION
gem 'actionpack', RAILS_VERSION
gem 'railties', RAILS_VERSION

gem 'moped', '~> 2.0.2'
gem 'mongoid', '~> 4.0.0'

gem 'mongoid_rails_migrations'
gem 'devise'
gem 'haml'
gem 'htmlentities'
gem 'rack-ssl', :require => 'rack/ssl'   # force SSL

gem 'useragent'
gem 'decent_exposure'
gem 'actionmailer_inline_css'
gem 'kaminari', '>= 0.14.1'
gem 'rack-ssl-enforcer', :require => false
gem 'rails_autolink'
# Please don't update hoptoad_notifier to airbrake.
# It's for internal use only, and we monkeypatch certain methods
gem 'hoptoad_notifier', "~> 2.4"
gem 'draper'

gem 'errbit_plugin'
gem 'errbit_github_plugin'

gem 'dotenv-rails'

# Notification services
# ---------------------------------------
gem 'campy'
# Hipchat
gem 'hipchat'
# Google Talk
gem 'xmpp4r', :require => ["xmpp4r", "xmpp4r/muc"]
# Hoiio (SMS)
gem 'hoi'
# Pushover (iOS Push notifications)
gem 'rushover'
# Hubot
gem 'httparty'
# Flowdock
gem 'flowdock'

# Authentication
# ---------------------------------------
# GitHub OAuth
gem 'omniauth-github'

gem 'ri_cal'
gem 'yajl-ruby', platform: 'ruby'
gem 'json', platform: 'jruby'

group :development, :test do
  gem 'airbrake', :require => false
  gem 'pry-rails'
  gem 'pry-byebug', platforms: [:mri]
  gem 'quiet_assets'
end

group :development do
  gem 'capistrano',         require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-rails',   require: false
  gem 'capistrano-rbenv',   require: false

  # better errors
  gem 'better_errors'
  gem 'binding_of_caller', platform: 'ruby'
  gem 'meta_request'
end

group :test do
  gem 'rspec'
  gem 'rspec-rails', '~> 3.0', require: false
  gem 'rspec-activemodel-mocks'
  gem 'rspec-its'
  gem 'mongoid-rspec', require: false
  gem 'fabrication'
  gem 'capybara'
  gem 'poltergeist'
  gem 'launchy'
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'timecop'
  gem 'test-unit', require: 'test/unit'
  gem 'coveralls', require: false
end

group :heroku, :production do
  gem 'rails_12factor', require: !!ENV["HEROKU"]
  gem 'unicorn', require: false, platform: 'ruby'
end

gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'
# We can't upgrade because not compatible to jquery >= 1.9.
# To do that, we need fix the rails.js
gem 'jquery-rails', '~> 2.1.4'
gem 'pjax_rails'
gem 'underscore-rails'

ENV['USER_GEMFILE'] ||= './UserGemfile'
eval_gemfile ENV['USER_GEMFILE'] if File.exist?(ENV['USER_GEMFILE'])
