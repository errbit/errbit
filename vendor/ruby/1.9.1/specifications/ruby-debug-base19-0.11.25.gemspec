# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "ruby-debug-base19"
  s.version = "0.11.25"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kent Sibilev", "Mark Moseley"]
  s.date = "2011-04-02"
  s.description = "ruby-debug is a fast implementation of the standard Ruby debugger debug.rb.\nIt is implemented by utilizing a new Ruby C API hook. The core component\nprovides support that front-ends can build on. It provides breakpoint\nhandling, bindings for stack frames among other things.\n"
  s.email = "mark@fast-software.com"
  s.extensions = ["ext/ruby_debug/extconf.rb"]
  s.extra_rdoc_files = ["README", "ext/ruby_debug/ruby_debug.c"]
  s.files = ["README", "ext/ruby_debug/ruby_debug.c", "ext/ruby_debug/extconf.rb"]
  s.homepage = "http://rubyforge.org/projects/ruby-debug19/"
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.2")
  s.rubyforge_project = "ruby-debug19"
  s.rubygems_version = "1.8.15"
  s.summary = "Fast Ruby debugger - core component"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<columnize>, [">= 0.3.1"])
      s.add_runtime_dependency(%q<ruby_core_source>, [">= 0.1.4"])
      s.add_runtime_dependency(%q<linecache19>, [">= 0.5.11"])
    else
      s.add_dependency(%q<columnize>, [">= 0.3.1"])
      s.add_dependency(%q<ruby_core_source>, [">= 0.1.4"])
      s.add_dependency(%q<linecache19>, [">= 0.5.11"])
    end
  else
    s.add_dependency(%q<columnize>, [">= 0.3.1"])
    s.add_dependency(%q<ruby_core_source>, [">= 0.1.4"])
    s.add_dependency(%q<linecache19>, [">= 0.5.11"])
  end
end
