# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "rspec-core"
  s.version = "2.6.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Chad Humphries", "David Chelimsky"]
  s.date = "2011-06-06"
  s.description = "BDD for Ruby. RSpec runner and example groups."
  s.email = "rspec-users@rubyforge.org;"
  s.executables = ["autospec", "rspec"]
  s.extra_rdoc_files = ["README.md"]
  s.files = ["bin/autospec", "bin/rspec", "README.md"]
  s.homepage = "http://github.com/rspec"
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "rspec"
  s.rubygems_version = "1.8.15"
  s.summary = "rspec-core-2.6.4"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
