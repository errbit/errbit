# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ruby_fogbugz/version"

Gem::Specification.new do |s|
  s.name        = "ruby-fogbugz"
  s.version     = Fogbugz::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Simon Hørup Eskildsen"]
  s.email       = ["sirup@sirupsen.com"]
  s.homepage    = ""
  s.summary     = %q{Ruby wrapper for the Fogbugz API }
  s.description = %q{A simple Ruby wrapper for the Fogbugz XML API}

  s.rubyforge_project = "ruby-fogbugz"

  s.add_dependency('typhoeus')
  s.add_dependency('crack')

  s.add_development_dependency('minitest')
  s.add_development_dependency('mocha')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
