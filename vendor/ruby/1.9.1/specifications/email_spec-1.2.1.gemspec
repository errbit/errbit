# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "email_spec"
  s.version = "1.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ben Mabey", "Aaron Gibralter", "Mischa Fierer"]
  s.date = "2011-06-20"
  s.description = "Easily test email in rspec and cucumber"
  s.email = "ben@benmabey.com"
  s.extra_rdoc_files = ["MIT-LICENSE.txt", "README.rdoc"]
  s.files = ["MIT-LICENSE.txt", "README.rdoc"]
  s.homepage = "http://github.com/bmabey/email-spec/"
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "email-spec"
  s.rubygems_version = "1.8.15"
  s.summary = "Easily test email in rspec and cucumber"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mail>, ["~> 2.2"])
      s.add_runtime_dependency(%q<rspec>, ["~> 2.0"])
    else
      s.add_dependency(%q<mail>, ["~> 2.2"])
      s.add_dependency(%q<rspec>, ["~> 2.0"])
    end
  else
    s.add_dependency(%q<mail>, ["~> 2.2"])
    s.add_dependency(%q<rspec>, ["~> 2.0"])
  end
end
