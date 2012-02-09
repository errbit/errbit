# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "ruby-debug19"
  s.version = "0.11.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kent Sibilev", "Mark Moseley"]
  s.date = "2009-09-01"
  s.description = "A generic command line interface for ruby-debug."
  s.email = "mark@fast-software.com"
  s.executables = ["rdebug"]
  s.files = ["bin/rdebug"]
  s.homepage = "http://rubyforge.org/projects/ruby-debug19/"
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["cli"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.2")
  s.rubyforge_project = "ruby-debug19"
  s.rubygems_version = "1.8.15"
  s.summary = "Command line interface (CLI) for ruby-debug-base"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<columnize>, [">= 0.3.1"])
      s.add_runtime_dependency(%q<linecache19>, [">= 0.5.11"])
      s.add_runtime_dependency(%q<ruby-debug-base19>, [">= 0.11.19"])
    else
      s.add_dependency(%q<columnize>, [">= 0.3.1"])
      s.add_dependency(%q<linecache19>, [">= 0.5.11"])
      s.add_dependency(%q<ruby-debug-base19>, [">= 0.11.19"])
    end
  else
    s.add_dependency(%q<columnize>, [">= 0.3.1"])
    s.add_dependency(%q<linecache19>, [">= 0.5.11"])
    s.add_dependency(%q<ruby-debug-base19>, [">= 0.11.19"])
  end
end
