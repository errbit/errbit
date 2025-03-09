source 'https://rubygems.org'

gem 'rails', '5.1.7'

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
gem 'mongoid'
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
gem 'hoptoad_notifier',
    git:    'https://github.com/errbit/hoptoad_notifier',
    branch: 'errbit'

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

gem 'ri_cal'
gem 'json'

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
  gem 'selenium-webdriver'
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

# lock concurrent-ruby gem to 1.1.10
gem 'concurrent-ruby', '1.1.10'

# lock i18n gem to 1.14.1
gem 'i18n', '1.14.1'

eval_gemfile "./UserGemfile"
