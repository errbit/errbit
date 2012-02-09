# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "mongo"
  s.version = "1.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jim Menard", "Mike Dirolf", "Kyle Banker"]
  s.date = "2011-05-11"
  s.description = "A Ruby driver for MongoDB. For more information about Mongo, see http://www.mongodb.org."
  s.email = "mongodb-dev@googlegroups.com"
  s.executables = ["mongo_console"]
  s.extra_rdoc_files = ["README.md"]
  s.files = ["bin/mongo_console", "README.md"]
  s.homepage = "http://www.mongodb.org"
  s.rdoc_options = ["--main", "README.md", "--inline-source"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.15"
  s.summary = "Ruby driver for the MongoDB"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<bson>, [">= 1.3.1"])
    else
      s.add_dependency(%q<bson>, [">= 1.3.1"])
    end
  else
    s.add_dependency(%q<bson>, [">= 1.3.1"])
  end
end
