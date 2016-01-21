source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.1.11'

gem 'pg'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# We can't upgrade because not compatible to jquery >= 1.9.
# To do that, we need fix the rails.js
gem 'jquery-rails', '~> 2.1.4'
gem 'pjax_rails'
gem 'underscore-rails'

# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platform: :ruby  # C Ruby (MRI) or Rubinius, but NOT Windows

gem 'devise'
gem 'haml'
gem 'htmlentities'
gem 'rack-ssl', require: 'rack/ssl'   # force SSL
gem 'rack-utf8_sanitizer', require: 'rack/utf8_sanitizer'

gem "paranoia", "~> 2.0"
gem 'useragent'
gem 'decent_exposure'
gem 'actionmailer_inline_css'
gem 'kaminari', '>= 0.14.1'
gem 'rack-ssl-enforcer', require: false
gem 'fabrication'
gem 'rails_autolink'
gem 'redcarpet'
gem 'progressbar', require: false
# Please don't update hoptoad_notifier to airbrake.
# It's for internal use only, and we monkeypatch certain methods
gem 'hoptoad_notifier', "~> 2.4"

# Need for mongodb data import
gem 'mongo', require: false
gem 'bson_ext', require: false

# Remove / comment out any of the gems below if you want to disable
# a given issue tracker, notification service, or authentication.

# Issue Trackers
# ---------------------------------------
# Lighthouse
gem 'lighthouse-api'
# Redmine
gem 'oruen_redmine_client', require: 'redmine_client'
# Pivotal Tracker
gem 'pivotal-tracker'
# Fogbugz
gem 'ruby-fogbugz', require: 'fogbugz'
# Github Issues
gem 'octokit'
# Gitlab
gem 'gitlab', '~> 3.0.0'

# Bitbucket Issues
gem 'bitbucket_rest_api', require: false

# Jira
gem 'jira-ruby', require: 'jira'

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
gem 'oj'
gem 'multi_json'

group :development, :test do
  gem 'rspec-rails', '~> 2.0'
  gem 'webmock', require: false
  gem 'airbrake', require: false
  gem 'pry-rails'
#  gem 'rpm_contrib'
#  gem 'newrelic_rpm'
  gem 'quiet_assets'
end

group :development do
  gem 'capistrano', '~> 2.0', require: false

  # better errors
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'foreman', require: false

  # Use puma for development
  gem 'puma', require: false

end

group :test do
  gem 'capybara'
  gem 'launchy'
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'timecop'
  gem 'test_after_commit'
  gem 'coveralls', require: false
end

group :heroku, :production do
  gem 'unicorn', require: false
end
