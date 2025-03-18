source "https://rubygems.org"

gem "rails", "6.1.7.10"

gem "activemodel-serializers-xml"
gem "actionmailer_inline_css"
gem "decent_exposure"
gem "devise"
gem "dotenv-rails"
gem "draper"
gem "errbit_plugin"
gem "errbit_github_plugin"
gem "font-awesome-rails"
gem "haml"
gem "htmlentities"
gem "kaminari"
gem "kaminari-mongoid"
gem "mongoid"
gem "omniauth"
gem "omniauth-rails_csrf_protection"
gem "omniauth-github"
gem "omniauth-google-oauth2"
gem "rack-ssl", require: "rack/ssl" # force SSL
gem "rack-ssl-enforcer", require: false
gem "rinku"
gem "useragent"
gem "uri"

# Please don't update hoptoad_notifier to airbrake.
# It's for internal use only, and we monkeypatch certain methods
gem "hoptoad_notifier",
  git: "https://github.com/errbit/hoptoad_notifier",
  branch: "errbit"

# Notification services
# ---------------------------------------
gem "campy"
# Google Talk
gem "xmpp4r", require: ["xmpp4r", "xmpp4r/muc"]
# Hoiio (SMS)
gem "hoi"
# Pushover (iOS Push notifications)
gem "rushover"
# Hubot
gem "httparty"

gem "ri_cal"
gem "json"

# For Ruby 2.7+
gem "bigdecimal", "3.1.9"

# Ruby 3.1 + Rails 6.1
gem "rexml"

gem "pry-rails"

group :development, :test do
  gem "airbrake", "~> 4.3.5", require: false
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-capybara", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-rspec_rails", require: false
  gem "rubocop-performance", require: false
  gem "standard", "1.47.0", require: false
end

group :development do
  gem "listen", "~> 3.0.5"
end

group :test do
  gem "rails-controller-testing"
  gem "rake"
  gem "rspec"
  gem "rspec-rails", require: false
  gem "rspec-activemodel-mocks"
  gem "mongoid-rspec", require: false
  gem "fabrication"
  gem "capybara"
  gem "selenium-webdriver"
  gem "launchy"
  gem "email_spec"
  gem "simplecov", require: false
  gem "super_diff"
end

gem "puma"
gem "jquery-rails"
gem "pjax_rails"
gem "underscore-rails"

gem "sucker_punch"

# lock concurrent-ruby gem to 1.1.10
gem "concurrent-ruby", "1.1.10"

# Lock zeitwerk gem for support JRuby 9.4
gem "zeitwerk", "2.6.18"

eval_gemfile "./UserGemfile"
