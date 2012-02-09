# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "rspec-mocks"
  s.version = "2.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Chelimsky", "Chad Humphries"]
  s.date = "2011-05-12"
  s.description = "RSpec's 'test double' framework, with support for stubbing and mocking"
  s.email = "dchelimsky@gmail.com;chad.humphries@gmail.com"
  s.extra_rdoc_files = ["README.md"]
  s.files = ["README.md"]
  s.homepage = "http://github.com/rspec/rspec-mocks"
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "rspec"
  s.rubygems_version = "1.8.15"
  s.summary = "rspec-mocks-2.6.0"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
