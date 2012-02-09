# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "heroku"
  s.version = "2.19.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Heroku"]
  s.date = "2012-02-01"
  s.description = "Client library and command-line tool to deploy and manage apps on Heroku."
  s.email = "support@heroku.com"
  s.executables = ["heroku"]
  s.files = ["bin/heroku"]
  s.homepage = "http://heroku.com/"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.10"
  s.summary = "Client library and CLI to deploy apps on Heroku."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<term-ansicolor>, ["~> 1.0.5"])
      s.add_runtime_dependency(%q<rest-client>, ["~> 1.6.1"])
      s.add_runtime_dependency(%q<launchy>, [">= 0.3.2"])
      s.add_runtime_dependency(%q<rubyzip>, [">= 0"])
    else
      s.add_dependency(%q<term-ansicolor>, ["~> 1.0.5"])
      s.add_dependency(%q<rest-client>, ["~> 1.6.1"])
      s.add_dependency(%q<launchy>, [">= 0.3.2"])
      s.add_dependency(%q<rubyzip>, [">= 0"])
    end
  else
    s.add_dependency(%q<term-ansicolor>, ["~> 1.0.5"])
    s.add_dependency(%q<rest-client>, ["~> 1.6.1"])
    s.add_dependency(%q<launchy>, [">= 0.3.2"])
    s.add_dependency(%q<rubyzip>, [">= 0"])
  end
end
