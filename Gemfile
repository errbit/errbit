source 'https://rubygems.org'

RAILS_VERSION = '~> 4.2.10'

send :ruby, ENV['GEMFILE_RUBY_VERSION'] if ENV['GEMFILE_RUBY_VERSION']

gem 'actionmailer', RAILS_VERSION
gem 'actionpack', RAILS_VERSION
gem 'railties', RAILS_VERSION

gem 'actionmailer_inline_css'
gem 'decent_exposure'
gem 'devise', '~> 4.4.0'
gem 'dotenv-rails'
gem 'draper'
gem 'errbit_plugin'
gem 'errbit_github_plugin'
gem 'font-awesome-rails'
gem 'haml'
gem 'htmlentities'
gem 'kaminari', '>= 0.16.3'
gem 'mongoid', '~> 5.4'
gem 'mongoid_rails_migrations'
gem 'rack-ssl', require: 'rack/ssl' # force SSL
gem 'rack-ssl-enforcer', require: false
gem 'rails_autolink'
gem 'useragent'

# Please don't update hoptoad_notifier to airbrake.
# It's for internal use only, and we monkeypatch certain methods
gem 'hoptoad_notifier', "~> 2.4"

# Notification services
# ---------------------------------------
gem 'campy'
# Hipchat
gem 'hipchat'
# Google Talk
gem 'xmpp4r', require: ["xmpp4r", "xmpp4r/muc"]
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
# Google OAuth
gem 'omniauth-google-oauth2'

gem 'ri_cal'
gem 'yajl-ruby', platform: 'ruby'
gem 'json', platform: 'jruby'

group :development, :test do
  gem 'airbrake', '~> 4.3.5', require: false
  gem 'pry-rails'
  gem 'pry-byebug', platforms: [:mri]
  gem 'quiet_assets'
  gem 'rubocop', require: false
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller', platform: 'ruby'
  gem 'meta_request'
end

group :test do
  gem 'rake'
  gem 'rspec'
  gem 'rspec-rails', require: false
  gem 'rspec-activemodel-mocks'
  gem 'mongoid-rspec', require: false
  gem 'fabrication'
  gem 'capybara'
  gem 'poltergeist'
  gem 'phantomjs'
  gem 'launchy'
  gem 'email_spec'
  gem 'timecop'
  gem 'coveralls', require: false
end

group :heroku, :production do
  gem 'rails_12factor', require: ENV.key?("HEROKU")
end

group :no_docker, :test, :development do
  gem 'therubyracer', platform: :ruby # C Ruby (MRI) or Rubinius, but NOT Windows
end

gem 'puma'
gem 'sass-rails'
gem 'uglifier'
gem 'jquery-rails'
gem 'pjax_rails'
gem 'underscore-rails'

gem 'sucker_punch'

ENV['USER_GEMFILE'] ||= './UserGemfile'
eval_gemfile ENV['USER_GEMFILE'] if File.exist?(ENV['USER_GEMFILE'])
