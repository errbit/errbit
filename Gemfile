source 'https://rubygems.org'

RAILS_VERSION = '~> 3.2.21'

gem 'actionmailer', RAILS_VERSION
gem 'actionpack', RAILS_VERSION
gem 'railties', RAILS_VERSION

gem 'mongoid'

gem 'mongoid_rails_migrations'
gem 'devise'
gem 'haml'
gem 'htmlentities'
gem 'rack-ssl', :require => 'rack/ssl'   # force SSL

gem 'useragent'
gem 'decent_exposure'
gem 'strong_parameters'
gem 'actionmailer_inline_css'
gem 'kaminari', '>= 0.14.1'
gem 'rack-ssl-enforcer', :require => false
gem 'fabrication'
gem 'rails_autolink'
# Please don't update hoptoad_notifier to airbrake.
# It's for internal use only, and we monkeypatch certain methods
gem 'hoptoad_notifier', "~> 2.4"
gem 'draper', :require => false

gem 'errbit_plugin'
gem 'errbit_bitbucket_plugin'
gem 'errbit_fogbugz_plugin'
gem 'errbit_github_plugin'
gem 'errbit_gitlab_plugin'
gem 'errbit_jira_plugin', :git => 'https://github.com/Astarodubtcev/errbit_jira_plugin.git', :branch => '0.3'
gem 'errbit_lighthouse_plugin'
gem 'errbit_pivotal_plugin', :git => 'https://github.com/Astarodubtcev/errbit_pivotal_plugin.git', :branch => '0.3'
gem 'errbit_redmine_plugin'
gem 'errbit_unfuddle_plugin'

# Notification services
# ---------------------------------------
gem 'campy'
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
# Flowdock
gem 'flowdock'

# Authentication
# ---------------------------------------
# GitHub OAuth
gem 'omniauth-github'

gem 'ri_cal'
gem 'yajl-ruby', :require => "yajl"

group :development, :test do
  gem 'rspec-rails'
  gem 'webmock', :require => false
  gem 'airbrake', :require => false
  gem 'pry-rails'
#  gem 'rpm_contrib'
#  gem 'newrelic_rpm'
  gem 'quiet_assets'
end

group :development do
  gem 'capistrano', '~> 2.0', :require => false

  # better errors
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'foreman', :require => false

  # Use puma for development
  gem 'puma', :require => false

end

group :test do
  gem 'capybara'
  gem 'poltergeist'
  gem 'launchy'
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'timecop'
  gem 'coveralls', :require => false
  gem 'mongoid-rspec', :require => false
end

group :heroku, :production do
  gem 'unicorn', :require => false
end


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'execjs'
  gem 'therubyracer', :platform => :ruby  # C Ruby (MRI) or Rubinius, but NOT Windows
  gem 'uglifier',     '>= 1.0.3'
  # We can't upgrade because not compatible to jquery >= 1.9.
  # To do that, we need fix the rails.js
  gem 'jquery-rails', '~> 2.1.4'
  gem 'pjax_rails'
  gem 'underscore-rails'
  gem 'turbo-sprockets-rails3'
end
