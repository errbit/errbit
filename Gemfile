source 'http://rubygems.org'

gem 'rails', '3.2.6'

gem 'nokogiri'
gem 'mongoid', '~> 2.4.10'

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
gem 'hoptoad_notifier', "~> 2.4"
gem 'actionmailer_inline_css', "~> 1.3.0"
gem 'kaminari'
gem 'rack-ssl-enforcer'
gem 'fabrication', "~> 1.3.0"   # Both for tests, and loading demo data
gem 'rails_autolink', '~> 1.0.9'

platform :ruby do
  gem 'mongo', '= 1.3.1'
  gem 'bson', '= 1.3.1'
  gem 'bson_ext', '= 1.3.1'
end

gem 'ri_cal'
gem 'yajl-ruby'

group :development, :test do
  gem 'rspec-rails', '~> 2.6'
  gem 'webmock', :require => false
  unless ENV["CI"]
    gem 'ruby-debug', :platform => :mri_18
    gem 'debugger', :platform => :mri_19
  end
  # gem 'rpm_contrib', :git => "git://github.com/bensymonds/rpm_contrib.git", :branch => "mongo-1.4.0_update"
end

group :test do
  gem 'capybara'
  gem 'launchy'
  gem 'rspec', '~> 2.6'
  gem 'database_cleaner', '~> 0.6.0'
  gem 'email_spec'
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
