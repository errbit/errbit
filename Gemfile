source 'http://rubygems.org'

gem 'rails', '3.2.8'
gem 'mongoid', '~> 2.4.10'
gem 'mongoid_rails_migrations'
gem 'devise', '~> 1.5.3'
gem 'nokogiri'
gem 'haml'
gem 'htmlentities', "~> 4.3.0"
gem 'rack-ssl', :require => 'rack/ssl'   # force SSL

gem 'useragent', '~> 0.3.1'
gem 'inherited_resources'
gem 'SystemTimer', :platform => :ruby_18
gem 'actionmailer_inline_css', "~> 1.3.0"
gem 'kaminari'
gem 'rack-ssl-enforcer'
gem 'fabrication', "~> 1.3.0"   # Used for both tests and demo data
gem 'rails_autolink', '~> 1.0.9'
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
gem 'octokit', '~> 1.0.0'

# Bitbucket Issues
gem 'bitbucket_rest_api'

# Notification services
# ---------------------------------------
# Campfire
gem 'campy'
# Hipchat
gem 'hipchat'
# Hoiio (SMS)
gem 'hoi'

# Authentication
# ---------------------------------------
# GitHub OAuth
gem 'omniauth-github'


platform :ruby do
  gem 'mongo', '= 1.6.2'
  gem 'bson', '= 1.6.2'
  gem 'bson_ext', '= 1.6.2'
end

gem 'omniauth'
gem 'oa-core'
gem 'ri_cal'
gem 'yajl-ruby', :require => "yajl"

group :development, :test do
  gem 'rspec-rails', '~> 2.6'
  gem 'webmock', :require => false
  unless ENV["CI"]
    gem 'ruby-debug', :platform => :mri_18
    gem 'debugger', :platform => :mri_19
    gem 'pry'
    gem 'pry-rails'
  end
#  gem 'rpm_contrib'
#  gem 'newrelic_rpm'
  gem 'capistrano'
  gem 'capistrano_colors'
end

group :test do
  gem 'capybara'
  gem 'launchy'
  gem 'rspec', '~> 2.6'
  gem 'database_cleaner', '~> 0.6.0'
  gem 'email_spec'
  gem 'timecop'
end

group :heroku do
  gem 'unicorn'
end

# Use thin for development
gem 'thin', :group => :development, :platform => :ruby

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'execjs'
  gem 'therubyracer', :platform => :ruby  # C Ruby (MRI) or Rubinius, but NOT Windows
  gem 'uglifier',     '>= 1.0.3'
end

gem 'turbo-sprockets-rails3'
