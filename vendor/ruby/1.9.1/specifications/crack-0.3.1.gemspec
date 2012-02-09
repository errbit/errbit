# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "crack"
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Nunemaker", "Wynn Netherland"]
  s.date = "2011-09-21"
  s.email = "nunemaker@gmail.com"
  s.extra_rdoc_files = ["LICENSE", "README.rdoc"]
  s.files = ["LICENSE", "README.rdoc"]
  s.homepage = "http://github.com/jnunemaker/crack"
  s.require_paths = ["lib"]
  s.rubyforge_project = "crack"
  s.rubygems_version = "1.8.15"
  s.summary = "Really simple JSON and XML parsing, ripped from Merb and Rails."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
