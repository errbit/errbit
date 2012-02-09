# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "css_parser"
  s.version = "1.2.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Alex Dunae"]
  s.date = "2011-09-07"
  s.description = "A set of classes for parsing CSS in Ruby."
  s.email = "code@dunae.ca"
  s.homepage = "https://github.com/alexdunae/css_parser"
  s.rdoc_options = ["--all", "--inline-source", "--line-numbers", "--charset", "utf-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.15"
  s.summary = "Ruby CSS parser."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<addressable>, [">= 0"])
    else
      s.add_dependency(%q<addressable>, [">= 0"])
    end
  else
    s.add_dependency(%q<addressable>, [">= 0"])
  end
end
