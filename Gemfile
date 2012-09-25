source 'http://rubygems.org'

gem 'rails', '3.2.8'

gem 'nokogiri'
gem 'mongoid', '~> 2.4.10'

# force SSL
gem 'rack-ssl', :require => 'rack/ssl'

gem 'haml'
gem 'htmlentities', "~> 4.3.0"

gem 'devise', '~> 1.5.3'

gem 'omniauth-github'
gem 'oa-core'

gem 'lighthouse-api'
gem 'oruen_redmine_client', :require => 'redmine_client'
gem 'mongoid_rails_migrations'
gem 'useragent', '~> 0.3.1'
gem 'pivotal-tracker'
gem 'ruby-fogbugz', :require => 'fogbugz'

gem 'octokit', '~> 1.0.0'

gem 'inherited_resources'
gem 'SystemTimer', :platform => :ruby_18
gem 'actionmailer_inline_css', "~> 1.3.0"
gem 'kaminari'
gem 'rack-ssl-enforcer'
gem 'fabrication', "~> 1.3.0"   # Both for tests, and loading demo data
gem 'rails_autolink', '~> 1.0.9'
gem 'campy'
gem 'hipchat'

# Please don't update this to airbrake - We override the send_notice method
# to handle internal errors.
gem 'hoptoad_notifier', "~> 2.4"

platform :ruby do
  gem 'mongo', '= 1.6.2'
  gem 'bson', '= 1.6.2'
  gem 'bson_ext', '= 1.6.2'
end

gem 'ri_cal'
gem 'yajl-ruby', :require => "yajl"

group :development, :test do
  gem 'rspec-rails', '~> 2.6'
  gem 'webmock', :require => false
  unless ENV["CI"]
    gem 'ruby-debug', :platform => :mri_18
    gem 'debugger', :platform => :mri_19
    gem 'pry'
  end
#  gem 'rpm_contrib'
#  gem 'newrelic_rpm'
  gem 'capistrano'
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
