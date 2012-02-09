# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "bson"
  s.version = "1.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jim Menard", "Mike Dirolf", "Kyle Banker"]
  s.date = "2011-05-11"
  s.description = "A Ruby BSON implementation for MongoDB. For more information about Mongo, see http://www.mongodb.org. For more information on BSON, see http://www.bsonspec.org."
  s.email = "mongodb-dev@googlegroups.com"
  s.executables = ["b2json", "j2bson"]
  s.files = ["bin/b2json", "bin/j2bson"]
  s.homepage = "http://www.mongodb.org"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.15"
  s.summary = "Ruby implementation of BSON"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
