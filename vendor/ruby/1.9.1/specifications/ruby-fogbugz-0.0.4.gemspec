# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "ruby-fogbugz"
  s.version = "0.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Simon H\u{c3}\u{b8}rup Eskildsen"]
  s.date = "2011-07-01"
  s.description = "A simple Ruby wrapper for the Fogbugz XML API"
  s.email = ["sirup@sirupsen.com"]
  s.homepage = ""
  s.require_paths = ["lib"]
  s.rubyforge_project = "ruby-fogbugz"
  s.rubygems_version = "1.8.15"
  s.summary = "Ruby wrapper for the Fogbugz API"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<typhoeus>, [">= 0"])
      s.add_runtime_dependency(%q<crack>, [">= 0"])
      s.add_development_dependency(%q<minitest>, [">= 0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
    else
      s.add_dependency(%q<typhoeus>, [">= 0"])
      s.add_dependency(%q<crack>, [">= 0"])
      s.add_dependency(%q<minitest>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0"])
    end
  else
    s.add_dependency(%q<typhoeus>, [">= 0"])
    s.add_dependency(%q<crack>, [">= 0"])
    s.add_dependency(%q<minitest>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0"])
  end
end
