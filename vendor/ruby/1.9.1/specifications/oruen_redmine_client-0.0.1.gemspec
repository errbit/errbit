# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "oruen_redmine_client"
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Eric Davis", "Nick Recobra"]
  s.date = "2011-08-25"
  s.description = "Access the Redmine REST API with ActiveResource"
  s.email = "oruenu@gmail.com"
  s.executables = ["test.rb"]
  s.extra_rdoc_files = ["LICENSE", "README.rdoc"]
  s.files = ["bin/test.rb", "LICENSE", "README.rdoc"]
  s.homepage = "http://github.com/oruen/redmine_client"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.15"
  s.summary = "Redmine API client"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activeresource>, [">= 2.3.0"])
      s.add_development_dependency(%q<thoughtbot-shoulda>, [">= 0"])
      s.add_development_dependency(%q<webmock>, [">= 0"])
    else
      s.add_dependency(%q<activeresource>, [">= 2.3.0"])
      s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
      s.add_dependency(%q<webmock>, [">= 0"])
    end
  else
    s.add_dependency(%q<activeresource>, [">= 2.3.0"])
    s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    s.add_dependency(%q<webmock>, [">= 0"])
  end
end
