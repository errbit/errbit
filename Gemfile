# frozen_string_literal: true

source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", "8.1.2"

gem "reactionview"
gem "sprockets-rails"
gem "stimulus-rails"
gem "importmap-rails"
gem "configurate"
gem "toml-rb"
gem "activemodel-serializers-xml"
gem "actionmailer_inline_css"
gem "decent_exposure"
gem "devise"
gem "pundit"
gem "dotenv"
gem "draper"
gem "errbit_plugin"
gem "errbit_github_plugin"
gem "font-awesome-rails"
gem "htmlentities"
gem "kaminari"
gem "kaminari-mongoid"
gem "kaminari-i18n"
gem "mongoid"
gem "faraday-retry"
gem "octokit"
gem "omniauth"
gem "omniauth-rails_csrf_protection"
gem "omniauth-github"
gem "omniauth-google-oauth2"
gem "rails_autolink"
gem "useragent"
gem "uri"
gem "rack-timeout", require: false
gem "puma"

# ~/.rbenv/versions/3.4.2/lib/ruby/gems/3.4.0/gems/mongoid-9.0.6/lib/mongoid/indexable.rb:6: warning: ~/.rbenv/versions/3.4.2/lib/ruby/3.4.0/ostruct.rb was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 3.5.0.
# You can add ostruct to your Gemfile or gemspec to silence this warning.
gem "ostruct"

# Please don't update hoptoad_notifier to airbrake.
# It's for internal use only, and we monkeypatch certain methods
gem "hoptoad_notifier",
  git: "https://github.com/errbit/hoptoad_notifier",
  branch: "errbit"

# Notification services
# ---------------------------------------
gem "campy"
# Hoiio (SMS)
gem "hoi"
# Pushover.net (iOS/Android Push notifications)
gem "pushover2"
# Hubot
gem "httparty"

gem "icalendar"
gem "json"

gem "pry-rails"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.4", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

group :development, :test do
  gem "airbrake", "~> 4.3.5", require: false
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-capybara", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-rspec_rails", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-disable_syntax", require: false
  gem "rubocop-thread_safety", require: false
  gem "rubocop-factory_bot", require: false
  gem "standard", "1.53.0", require: false
  gem "faker"
  gem "factory_bot_rails"
  gem "brakeman", require: false
  gem "herb", require: false
end

group :development do
  gem "listen", "~> 3.10"
  gem "bundler-audit", require: false
end

group :test do
  gem "rails-controller-testing"
  gem "rspec-rails", require: false
  gem "rspec-rebound", require: false
  gem "rspec-activemodel-mocks"
  gem "mongoid-rspec"
  gem "pundit-matchers"
  gem "capybara"
  gem "selenium-webdriver"
  gem "launchy"
  gem "email_spec"
  gem "simplecov", require: false
  gem "super_diff"
  gem "webmock"
  gem "vcr"
end

gem "jquery-rails"
gem "pjax_rails"
gem "underscore-rails"

eval_gemfile "./UserGemfile"
