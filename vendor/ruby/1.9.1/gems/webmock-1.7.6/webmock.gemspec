# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'webmock/version'

Gem::Specification.new do |s|
  s.name        = 'webmock'
  s.version     = WebMock::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Bartosz Blimke']
  s.email       = ['bartosz.blimke@gmail.com']
  s.homepage    = 'http://github.com/bblimke/webmock'
  s.summary     = %q{Library for stubbing HTTP requests in Ruby.}
  s.description = %q{WebMock allows stubbing HTTP requests and setting expectations on HTTP requests.}

  s.rubyforge_project = 'webmock'

  s.add_dependency 'addressable', '~> 2.2', '> 2.2.5'
  s.add_dependency 'crack', '>=0.1.7'

  s.add_development_dependency 'rspec',           '>= 2.0.0'
  s.add_development_dependency 'httpclient',      '>= 2.1.5.2'
  s.add_development_dependency 'patron',          '>= 0.4.15'
  s.add_development_dependency 'em-http-request', '~> 0.3.0'
  s.add_development_dependency 'curb',            '>= 0.7.8'
  s.add_development_dependency 'typhoeus',        '>= 0.2.4'
  s.add_development_dependency 'minitest',        '>= 2.2.2'
  s.add_development_dependency 'rdoc',            ((RUBY_VERSION == '1.8.6') ? '<= 3.5.0' : '>3.5.0')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
