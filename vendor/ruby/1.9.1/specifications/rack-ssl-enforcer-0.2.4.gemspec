# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "rack-ssl-enforcer"
  s.version = "0.2.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tobias Matthies", "Thibaud Guillaume-Gentil"]
  s.date = "2011-09-05"
  s.description = "Rack::SslEnforcer is a simple Rack middleware to enforce ssl connections"
  s.email = ["tm@mit2m.de", "thibaud@thibaud.me"]
  s.homepage = "http://github.com/tobmatth/rack-ssl-enforcer"
  s.require_paths = ["lib"]
  s.rubyforge_project = "rack-ssl-enforcer"
  s.rubygems_version = "1.8.15"
  s.summary = "A simple Rack middleware to enforce SSL"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
      s.add_development_dependency(%q<test-unit>, ["~> 2.3"])
      s.add_development_dependency(%q<shoulda>, ["~> 2.11.3"])
      s.add_development_dependency(%q<rack>, ["~> 1.2.0"])
      s.add_development_dependency(%q<rack-test>, ["~> 0.5.4"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<test-unit>, ["~> 2.3"])
      s.add_dependency(%q<shoulda>, ["~> 2.11.3"])
      s.add_dependency(%q<rack>, ["~> 1.2.0"])
      s.add_dependency(%q<rack-test>, ["~> 0.5.4"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<test-unit>, ["~> 2.3"])
    s.add_dependency(%q<shoulda>, ["~> 2.11.3"])
    s.add_dependency(%q<rack>, ["~> 1.2.0"])
    s.add_dependency(%q<rack-test>, ["~> 0.5.4"])
  end
end
