# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "useragent"
  s.version = "0.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joshua Peek"]
  s.date = "2011-06-29"
  s.description = "    HTTP User Agent parser\n"
  s.email = "josh@joshpeek.com"
  s.homepage = "http://github.com/josh/useragent"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.15"
  s.summary = "HTTP User Agent parser"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
