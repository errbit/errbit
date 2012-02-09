# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "ri_cal"
  s.version = "0.8.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Rick DeNatale"]
  s.date = "2011-02-13"
  s.description = "A new Ruby implementation of RFC2445 iCalendar.\n\nThe existing Ruby iCalendar libraries (e.g. icalendar, vpim) provide for parsing and generating icalendar files,\nbut do not support important things like enumerating occurrences of repeating events.\n\nThis is a clean-slate implementation of RFC2445.\n\nA Google group for discussion of this library has been set up http://groups.google.com/group/rical_gem\n    "
  s.email = "rick.denatale@gmail.com"
  s.executables = ["ri_cal"]
  s.extra_rdoc_files = ["History.txt", "README.txt", "copyrights.txt"]
  s.files = ["bin/ri_cal", "History.txt", "README.txt", "copyrights.txt"]
  s.homepage = "http://github.com/rubyredrick/ri_cal"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.15"
  s.summary = "a new implementation of RFC2445 in Ruby"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
