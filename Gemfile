source 'https://rubygems.org'

RAILS_VERSION = '5.0.7.2'
# RAILS_VERSION = '5.1.7'

ruby File.read(".ruby-version")

gem 'actionmailer', RAILS_VERSION
gem 'actionpack', RAILS_VERSION
gem 'railties', RAILS_VERSION

gem 'activemodel-serializers-xml'
gem 'actionmailer_inline_css'
gem 'decent_exposure'
gem 'devise'
gem 'dotenv-rails'
gem 'draper'
gem 'errbit_plugin'
gem 'errbit_github_plugin'
gem 'font-awesome-rails'
gem 'haml'
gem 'htmlentities'
gem 'kaminari'
gem 'kaminari-mongoid'
gem 'mongoid', '6.0.3'
gem 'omniauth'
gem 'omniauth-rails_csrf_protection'
gem 'omniauth-github'
gem 'omniauth-google-oauth2'
gem 'rack-ssl', require: 'rack/ssl' # force SSL
gem 'rack-ssl-enforcer', require: false
gem 'rinku'
gem 'useragent'

# Please don't update hoptoad_notifier to airbrake.
# It's for internal use only, and we monkeypatch certain methods
gem 'hoptoad_notifier', "~> 2.4"

# Notification services
# ---------------------------------------
gem 'campy'
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

gem 'ri_cal'
gem 'json', platform: 'jruby'

# For Ruby 2.7
gem 'bigdecimal', '~> 1.4.4'

gem 'pry-rails'

group :development, :test do
  gem 'airbrake', '~> 4.3.5', require: false
  gem 'rubocop', '~> 0.71.0', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
end

group :development do
  gem 'listen', '~> 3.0.5'
  gem 'better_errors'
  gem 'binding_of_caller', platform: 'ruby'
  gem 'meta_request'
end

group :test do
  gem 'rails-controller-testing'
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

group :no_docker, :test, :development do
  gem 'mini_racer', platform: :ruby # C Ruby (MRI) or Rubinius, but NOT Windows
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
