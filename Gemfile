source 'https://rubygems.org'

RAILS_VERSION = '~> 7.0.0'

send :ruby, ENV['GEMFILE_RUBY_VERSION'] if ENV['GEMFILE_RUBY_VERSION']

gem 'actionmailer', RAILS_VERSION
gem 'actionpack', RAILS_VERSION
gem 'railties', RAILS_VERSION

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# gem 'actionmailer_inline_css'
gem 'decent_exposure'
gem 'devise', '~> 4.7'
gem 'dotenv-rails'
gem 'draper'
gem 'errbit_plugin'
gem 'errbit_github_plugin'
gem 'font-awesome-rails'
gem 'haml'
gem 'htmlentities'
gem 'mongoid'
gem 'kaminari'
gem 'kaminari-mongoid'
gem 'omniauth'
gem 'omniauth-github'
gem 'omniauth-google-oauth2'
# gem 'rack-ssl', require: 'rack/ssl' # force SSL
# gem 'rack-ssl-enforcer', require: false
# gem 'rinku'
gem 'useragent'
# TODO: check, where rexml gem used and how.
gem "rexml"

gem "pry-rails"

# Please don't update hoptoad_notifier to airbrake.
# It's for internal use only, and we monkeypatch certain methods
# TODO: Added require: false to ignore start problem.
# TODO: Make something with this gem, it's 11 years old
gem 'hoptoad_notifier', "~> 2.4", require: false

# Notification services
# ---------------------------------------
# TODO: campy looks like dead. 9 years without release???
gem 'campy'
# # Google Talk
# gem 'xmpp4r', require: ["xmpp4r", "xmpp4r/muc"]
# # Hoiio (SMS)
# gem 'hoi'
# # Pushover (iOS Push notifications)
# gem 'rushover'
# # Hubot
# gem 'httparty'
# Slack
gem 'httparty'
# Flowdock
# TODO: flowdock looks like dead. 6 years without release???
gem 'flowdock'

# TODO: looks like dead. 10 years without releases
gem 'ri_cal'
# gem 'yajl-ruby', platform: 'ruby'
# gem 'json', platform: 'jruby'
#
# # For Ruby 2.7
# gem 'bigdecimal', '~> 1.4.4'

group :development, :test do
  gem 'rspec-rails'
  # TODO: update???
  gem 'airbrake', '~> 4.3.5', require: false
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
end

# group :development, :test do
#   gem 'pry-rails'
#   gem 'pry-byebug', platforms: [:mri]
#   gem 'quiet_assets'
# end
#
# group :development do
#   gem 'better_errors'
#   gem 'binding_of_caller', platform: 'ruby'
#   gem 'meta_request'
# end

group :test do
#   gem 'rake'
  gem 'rspec-activemodel-mocks'
  gem 'rails-controller-testing'
  gem 'mongoid-rspec'
  gem 'fabrication'
#   gem 'capybara'
#   gem 'poltergeist'
#   gem 'phantomjs'
#   gem 'launchy'
  # TODO: remove later???
  gem 'email_spec'
#   gem 'timecop'
#   gem 'coveralls', require: false
end

# group :heroku, :production do
#   gem 'rails_12factor', require: ENV.key?("HEROKU")
# end
#
# # group :no_docker, :test, :development do
# #   gem 'mini_racer', '~> 0.3.1', platform: :ruby # C Ruby (MRI) or Rubinius, but NOT Windows
# # end

gem 'puma'
gem 'sassc-rails'
# gem 'uglifier'
gem 'jquery-rails'
gem 'pjax_rails'
gem 'underscore-rails'

gem 'sucker_punch'

ENV['USER_GEMFILE'] ||= './UserGemfile'
eval_gemfile ENV['USER_GEMFILE'] if File.exist?(ENV['USER_GEMFILE'])
