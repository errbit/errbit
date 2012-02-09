source 'http://rubygems.org/'

gemspec
if ENV["EM_HTTP_REQUEST_1_X"]
  gem 'em-http-request', '>= 1.0.0'
  gem 'em-synchrony', '>= 1.0.0'
end


group :development do
  gem 'rake'
  gem 'guard-rspec'
  gem 'rb-fsevent'
end

group :test do
  gem 'rack'
end

platforms :jruby do
  gem 'jruby-openssl', '~> 0.7'
end
