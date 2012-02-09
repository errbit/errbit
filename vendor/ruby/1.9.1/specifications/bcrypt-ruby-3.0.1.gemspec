# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "bcrypt-ruby"
  s.version = "3.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Coda Hale"]
  s.date = "2011-09-12"
  s.description = "    bcrypt() is a sophisticated and secure hash algorithm designed by The OpenBSD project\n    for hashing passwords. bcrypt-ruby provides a simple, humane wrapper for safely handling\n    passwords.\n"
  s.email = "coda.hale@gmail.com"
  s.extensions = ["ext/mri/extconf.rb"]
  s.extra_rdoc_files = ["README.md", "COPYING", "CHANGELOG", "lib/bcrypt.rb", "lib/bcrypt_engine.rb"]
  s.files = ["README.md", "COPYING", "CHANGELOG", "lib/bcrypt.rb", "lib/bcrypt_engine.rb", "ext/mri/extconf.rb"]
  s.homepage = "http://bcrypt-ruby.rubyforge.org"
  s.rdoc_options = ["--title", "bcrypt-ruby", "--line-numbers", "--inline-source", "--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "bcrypt-ruby"
  s.rubygems_version = "1.8.15"
  s.summary = "OpenBSD's bcrypt() password hashing algorithm."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake-compiler>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<rake-compiler>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake-compiler>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
