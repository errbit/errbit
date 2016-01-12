source 'https://rubygems.org'

RAILS_VERSION = '~> 4.2.0'

send :ruby, ENV['GEMFILE_RUBY_VERSION'] if ENV['GEMFILE_RUBY_VERSION']

detected_ruby_version = Gem::Version.new(RUBY_VERSION.dup)
required_ruby_version = Gem::Version.new('2.1.0') # minimum supported version

if detected_ruby_version < required_ruby_version
  fail "RUBY_VERSION must be at least #{required_ruby_version}, " \
       "detected RUBY_VERSION #{RUBY_VERSION}"
end

gem 'actionmailer', RAILS_VERSION
gem 'actionpack', RAILS_VERSION
gem 'railties', RAILS_VERSION

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
gem 'kaminari', '>= 0.14.1'
gem 'mongoid', '5.0.2'
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

gem 'ri_cal'
gem 'yajl-ruby', platform: 'ruby'
gem 'json', platform: 'jruby'

group :development, :test do
  gem 'airbrake', require: false
  gem 'pry-rails'
  gem 'pry-byebug', platforms: [:mri]
  gem 'quiet_assets'
  gem 'rubocop', require: false
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
  gem 'rspec', '~> 3.3'
  gem 'rspec-rails', '~> 3.0', require: false
  gem 'rspec-activemodel-mocks'
  gem 'rspec-its'
  gem 'mongoid-rspec', '~> 3.0.0', require: false
  gem 'fabrication'
  gem 'capybara'
  gem 'poltergeist'
  gem 'launchy'
  gem 'email_spec'
  gem 'timecop'
  gem 'coveralls', require: false
end

group :heroku, :production do
  gem 'rails_12factor', require: ENV.key?("HEROKU")
  gem 'unicorn', require: false, platform: 'ruby'
  gem 'unicorn-worker-killer'
end

gem 'therubyracer', platform: :ruby # C Ruby (MRI) or Rubinius, but NOT Windows
gem 'sass-rails'
gem 'uglifier'
# We can't upgrade because not compatible to jquery >= 1.9.
# To do that, we need fix the rails.js
gem 'jquery-rails', '~> 2.1.4'
gem 'pjax_rails'
gem 'underscore-rails'

ENV['USER_GEMFILE'] ||= './UserGemfile'
eval_gemfile ENV['USER_GEMFILE'] if File.exist?(ENV['USER_GEMFILE'])
