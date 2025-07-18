# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "8.0.2"

gem "sprockets-rails"
gem "activemodel-serializers-xml"
gem "actionmailer_inline_css"
gem "decent_exposure"
gem "devise"
gem "pundit"
gem "dotenv-rails"
gem "draper"
gem "errbit_plugin"
gem "errbit_github_plugin"
gem "font-awesome-rails"
gem "haml"
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
gem "rack-timeout"

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
gem "bigdecimal", "3.2.2"

# Ruby 3.1 + Rails 6.1
gem "rexml"

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
  gem "standard", "1.50.0", require: false
  gem "faker"
  gem "factory_bot_rails"
  gem "brakeman", require: false
end

group :development do
  gem "listen", "~> 3.5"
  gem "bundler-audit", require: false
end

group :test do
  gem "rails-controller-testing"
  gem "rspec-rails", require: false
  gem "rspec-retry", require: false
  gem "rspec-activemodel-mocks"
  gem "mongoid-rspec"
  gem "pundit-matchers"
  gem "fabrication"
  gem "capybara"
  gem "selenium-webdriver"
  gem "launchy"
  gem "email_spec"
  gem "simplecov", require: false
  gem "super_diff"
  gem "webmock"
  gem "vcr"
end

gem "puma"
gem "jquery-rails"
gem "pjax_rails"
gem "underscore-rails"

gem "sucker_punch"

eval_gemfile "./UserGemfile"
