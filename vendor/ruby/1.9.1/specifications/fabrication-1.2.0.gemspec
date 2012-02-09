# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "fabrication"
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Paul Elliott"]
  s.date = "2011-09-26"
  s.description = "Fabrication is an object generation framework for ActiveRecord, Mongoid, and Sequel. It has a sensible syntax and lazily generates ActiveRecord associations!"
  s.email = ["paul@hashrocket.com"]
  s.homepage = "http://github.com/paulelliott/fabrication"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.15"
  s.summary = "Fabrication provides a robust solution for test object generation."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<activerecord>, ["~> 3.0.9"])
      s.add_development_dependency(%q<bson_ext>, ["~> 1.3.1"])
      s.add_development_dependency(%q<cucumber>, [">= 0"])
      s.add_development_dependency(%q<ffaker>, [">= 0"])
      s.add_development_dependency(%q<fuubar>, [">= 0"])
      s.add_development_dependency(%q<fuubar-cucumber>, [">= 0"])
      s.add_development_dependency(%q<mongoid>, ["~> 2.1.3"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<sequel>, ["~> 3.25.0"])
      s.add_development_dependency(%q<sqlite3-ruby>, [">= 0"])
    else
      s.add_dependency(%q<activerecord>, ["~> 3.0.9"])
      s.add_dependency(%q<bson_ext>, ["~> 1.3.1"])
      s.add_dependency(%q<cucumber>, [">= 0"])
      s.add_dependency(%q<ffaker>, [">= 0"])
      s.add_dependency(%q<fuubar>, [">= 0"])
      s.add_dependency(%q<fuubar-cucumber>, [">= 0"])
      s.add_dependency(%q<mongoid>, ["~> 2.1.3"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<sequel>, ["~> 3.25.0"])
      s.add_dependency(%q<sqlite3-ruby>, [">= 0"])
    end
  else
    s.add_dependency(%q<activerecord>, ["~> 3.0.9"])
    s.add_dependency(%q<bson_ext>, ["~> 1.3.1"])
    s.add_dependency(%q<cucumber>, [">= 0"])
    s.add_dependency(%q<ffaker>, [">= 0"])
    s.add_dependency(%q<fuubar>, [">= 0"])
    s.add_dependency(%q<fuubar-cucumber>, [">= 0"])
    s.add_dependency(%q<mongoid>, ["~> 2.1.3"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<sequel>, ["~> 3.25.0"])
    s.add_dependency(%q<sqlite3-ruby>, [">= 0"])
  end
end
