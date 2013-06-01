source 'http://rubygems.org'

gem 'rails', '3.2.13'
gem 'mongoid', '~> 2.7.1'
gem 'mongoid_rails_migrations'
gem 'devise', '~> 1.5.4'
gem 'haml'
gem 'htmlentities'
gem 'rack-ssl', :require => 'rack/ssl'   # force SSL

gem 'useragent'
gem 'inherited_resources'
gem 'SystemTimer', :platform => :ruby_18
gem 'actionmailer_inline_css', "~> 1.3.0"
gem 'kaminari', '>= 0.14.1'
gem 'rack-ssl-enforcer'
# fabrication 1.3.0 is last supporting ruby 1.8. Update when stop supporting this version too
gem 'fabrication', "~> 1.3.0"   # Used for both tests and demo data
gem 'rails_autolink'
# Please don't update hoptoad_notifier to airbrake.
# It's for internal use only, and we monkeypatch certain methods
gem 'hoptoad_notifier', "~> 2.4"


# Remove / comment out any of the gems below if you want to disable
# a given issue tracker, notification service, or authentication.

# Issue Trackers
# ---------------------------------------
# Lighthouse
gem 'lighthouse-api'
# Redmine
gem 'oruen_redmine_client', :require => 'redmine_client'
# Pivotal Tracker
gem 'pivotal-tracker'
# Fogbugz
gem 'ruby-fogbugz', :require => 'fogbugz'
# Github Issues
gem 'octokit'
# Gitlab
gem 'gitlab', :git => 'https://github.com/NARKOZ/gitlab.git'

# Bitbucket Issues
gem 'bitbucket_rest_api'

# Unfuddle
gem "taskmapper", "~> 0.8.0"
gem "taskmapper-unfuddle", "~> 0.7.0"

# Notification services
# ---------------------------------------
# Campfire ( We can't upgrade to 1.0 because drop support of ruby 1.8
gem 'campy', '0.1.3'
# Hipchat
gem 'hipchat'
# Google Talk
gem 'xmpp4r', :require => ["xmpp4r", "xmpp4r/muc"]
# Hoiio (SMS)
gem 'hoi'
# Pushover (iOS Push notifications)
gem 'rushover'
# Hubot
gem 'httparty'

# Authentication
# ---------------------------------------
# GitHub OAuth
gem 'omniauth-github'


platform :ruby do
  gem 'mongo'
  gem 'bson'
  gem 'bson_ext'
end

gem 'ri_cal'
gem 'yajl-ruby', :require => "yajl"

group :development, :test do
  gem 'rspec-rails', '~> 2.6'
  gem 'webmock', :require => false
  gem 'airbrake', :require => false
  unless ENV["CI"]
    gem 'ruby-debug', :platform => :mri_18
    gem 'debugger', :platform => :mri_19
    gem 'pry-rails'
  end
#  gem 'rpm_contrib'
#  gem 'newrelic_rpm'
end

group :development do
  gem 'capistrano'

  # better errors
  gem 'better_errors'    , :platform => :ruby_19
  gem 'binding_of_caller', :platform => :ruby_19
  gem 'meta_request'     , :platform => :ruby_19
  gem 'foreman'

  # Use thin for development
  gem 'thin', :group => :development, :platform => :ruby

end

group :test do
  # Capybara 2.1.0 no more support 1.8.7 ruby version
  gem 'capybara', "~> 2.0.1"
  gem 'launchy'
  # DatabaseCleaner 1.0.0 drop the support of ruby 1.8.7
  gem 'database_cleaner', '~> 0.9.0'
  gem 'email_spec'
  gem 'timecop'
  gem 'coveralls', :require => false
end

group :heroku, :production do
  gem 'unicorn'
end


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'execjs'
  gem 'therubyracer', :platform => :ruby  # C Ruby (MRI) or Rubinius, but NOT Windows
  gem 'uglifier',     '>= 1.0.3'
  gem 'jquery-rails'
  gem 'pjax_rails'
  gem 'underscore-rails'
  gem 'turbo-sprockets-rails3'
end
