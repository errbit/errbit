# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "mongoid_rails_migrations"
  s.version = "0.0.14"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.authors = ["Alan Da Costa"]
  s.date = "2010-05-12"
  s.description = "Migrations for the migrator."
  s.email = "alandacosta@gmail.com.com"
  s.homepage = "http://github.com/adacosta/mongoid_rails_migrations"
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.6")
  s.rubygems_version = "1.8.15"
  s.summary = "Data migrations for Mongoid in Active Record style, minus column input."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<bundler>, [">= 1.0.0"])
      s.add_runtime_dependency(%q<rails>, [">= 3.0.0"])
      s.add_runtime_dependency(%q<railties>, [">= 3.0.0"])
      s.add_runtime_dependency(%q<activesupport>, [">= 3.0.0"])
      s.add_development_dependency(%q<mongoid>, [">= 2.0.0"])
    else
      s.add_dependency(%q<bundler>, [">= 1.0.0"])
      s.add_dependency(%q<rails>, [">= 3.0.0"])
      s.add_dependency(%q<railties>, [">= 3.0.0"])
      s.add_dependency(%q<activesupport>, [">= 3.0.0"])
      s.add_dependency(%q<mongoid>, [">= 2.0.0"])
    end
  else
    s.add_dependency(%q<bundler>, [">= 1.0.0"])
    s.add_dependency(%q<rails>, [">= 3.0.0"])
    s.add_dependency(%q<railties>, [">= 3.0.0"])
    s.add_dependency(%q<activesupport>, [">= 3.0.0"])
    s.add_dependency(%q<mongoid>, [">= 2.0.0"])
  end
end
