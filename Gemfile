# frozen_string_literal: true

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
gem "rails_autolink"
gem "useragent"
gem "uri"

# ~/.rbenv/versions/3.3.7/lib/ruby/gems/3.3.0/gems/activesupport-6.1.7.10/lib/active_support/dependencies.rb:299: warning: mutex_m was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 3.4.0.
# You can add mutex_m to your Gemfile or gemspec to silence this warning.
# Also please contact the author of activesupport-6.1.7.10 to request adding mutex_m into its gemspec.
# ~/.rbenv/versions/3.3.7/lib/ruby/gems/3.3.0/gems/activesupport-6.1.7.10/lib/active_support/testing/parallelization.rb:3: warning: drb was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 3.4.0.
# You can add drb to your Gemfile or gemspec to silence this warning.
gem "mutex_m"
gem "drb"

# ~/.rbenv/versions/3.4.2/lib/ruby/gems/3.4.0/gems/activesupport-6.1.7.10/lib/active_support/dependencies.rb:299: warning: benchmark was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 3.5.0.
# You can add benchmark to your Gemfile or gemspec to silence this warning.
# Also please contact the author of activesupport-6.1.7.10 to request adding benchmark into its gemspec.
# ~/.rbenv/versions/3.4.2/lib/ruby/gems/3.4.0/gems/activesupport-6.1.7.10/lib/active_support/dependencies.rb:299: warning: ostruct was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 3.5.0.
# You can add ostruct to your Gemfile or gemspec to silence this warning.
# Also please contact the author of mongoid-9.0.6 to request adding ostruct into its gemspec.
gem "benchmark"
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
  gem "rubocop-disable_syntax", require: false
  gem "standard", "1.47.0", require: false
  gem "faker"
end

group :development do
  gem "listen", "~> 3.5"
end

group :test do
  gem "rails-controller-testing"
  gem "rake"
  gem "rspec"
  gem "rspec-rails", require: false
  gem "rspec-pending_for"
  gem "rspec-activemodel-mocks"
  gem "mongoid-rspec"
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

# https://stackoverflow.com/questions/79360526/uninitialized-constant-activesupportloggerthreadsafelevellogger-nameerror
gem "concurrent-ruby", "1.3.4"

# Lock zeitwerk gem for support JRuby 9.4
gem "zeitwerk", "2.6.18"

eval_gemfile "./UserGemfile"
