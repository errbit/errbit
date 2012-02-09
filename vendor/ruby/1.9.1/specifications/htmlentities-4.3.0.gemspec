# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "htmlentities"
  s.version = "4.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Paul Battley"]
  s.date = "2011-03-29"
  s.email = "pbattley@gmail.com"
  s.extra_rdoc_files = ["History.txt", "COPYING.txt"]
  s.files = ["History.txt", "COPYING.txt"]
  s.homepage = "http://htmlentities.rubyforge.org/"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.15"
  s.summary = "A module for encoding and decoding (X)HTML entities."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
