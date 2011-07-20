source 'http://rubygems.org'

gem 'rails', '3.0.5'
gem 'nokogiri'
gem 'mongoid', '2.0.2'
gem 'haml'
gem 'will_paginate'
gem 'devise', '~> 1.1.8'
gem 'lighthouse-api'
gem 'redmine_client', :git => "git://github.com/oruen/redmine_client.git"
gem 'mongoid_rails_migrations'
gem 'useragent', '~> 0.3.1'
gem 'pivotal-tracker'
gem 'ruby-fogbugz', :require => 'fogbugz', :path => '/Users/tracey/Development/gems/ruby-fogbugz'

platform :ruby do
  gem 'bson_ext', '~> 1.3.1'
end

group :development, :test do
  gem 'rspec-rails', '~> 2.5'
  gem 'webmock', :require => false
  gem 'ruby-debug19', :require => 'ruby-debug'
end

group :test do
  gem 'rspec', '~> 2.5'
  gem 'database_cleaner', '~> 0.6.0'
  gem 'factory_girl_rails'
  gem 'email_spec'
end

group :heroku do
  gem 'thin'
end
