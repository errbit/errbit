# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "libxml-ruby"
  s.version = "2.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ross Bamform", "Wai-Sun Chia", "Sean Chittenden", "Dan Janwoski", "Anurag Priyam", "Charlie Savage"]
  s.date = "2011-08-29"
  s.description = "    The Libxml-Ruby project provides Ruby language bindings for the GNOME\n    Libxml2 XML toolkit. It is free software, released under the MIT License.\n    Libxml-ruby's primary advantage over REXML is performance - if speed\n    is your need, these are good libraries to consider, as demonstrated\n    by the informal benchmark below.\n"
  s.extensions = ["ext/libxml/extconf.rb"]
  s.files = ["ext/libxml/extconf.rb"]
  s.homepage = "http://xml4r.github.com/libxml-ruby"
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.6")
  s.rubygems_version = "1.8.15"
  s.summary = "Ruby Bindings for LibXML2"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
