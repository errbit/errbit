# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "rspec-expectations"
  s.version = "2.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Chelimsky", "Chad Humphries"]
  s.date = "2011-05-12"
  s.description = "rspec expectations (should[_not] and matchers)"
  s.email = "dchelimsky@gmail.com;chad.humphries@gmail.com"
  s.extra_rdoc_files = ["README.md"]
  s.files = ["README.md"]
  s.homepage = "http://github.com/rspec/rspec-expectations"
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "rspec"
  s.rubygems_version = "1.8.15"
  s.summary = "rspec-expectations-2.6.0"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<diff-lcs>, ["~> 1.1.2"])
    else
      s.add_dependency(%q<diff-lcs>, ["~> 1.1.2"])
    end
  else
    s.add_dependency(%q<diff-lcs>, ["~> 1.1.2"])
  end
end
