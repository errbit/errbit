source "http://rubygems.org"

gem 'rake'

gemspec

group :development, :test do
  unless ENV['TRAVIS']
    gem 'ruby-debug', :platform => :mri_18
    gem 'ruby-debug19', :platform => :mri_19, :require => 'ruby-debug'
  end
end

