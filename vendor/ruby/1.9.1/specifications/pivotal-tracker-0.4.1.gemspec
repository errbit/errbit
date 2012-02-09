# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "pivotal-tracker"
  s.version = "0.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Justin Smestad", "Josh Nichols", "Terence Lee"]
  s.date = "2011-07-10"
  s.email = "justin.smestad@gmail.com"
  s.extra_rdoc_files = ["LICENSE", "README.rdoc"]
  s.files = ["LICENSE", "README.rdoc"]
  s.homepage = "http://github.com/jsmestad/pivotal-tracker"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.15"
  s.summary = "Ruby wrapper for the Pivotal Tracker API"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-client>, ["~> 1.6.0"])
      s.add_runtime_dependency(%q<happymapper>, [">= 0.3.2"])
      s.add_runtime_dependency(%q<builder>, [">= 0"])
      s.add_runtime_dependency(%q<nokogiri>, ["~> 1.4"])
      s.add_runtime_dependency(%q<rest-client>, ["~> 1.6.0"])
      s.add_runtime_dependency(%q<happymapper>, [">= 0.3.2"])
      s.add_runtime_dependency(%q<builder>, [">= 0"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 1.4.3"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.12"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
      s.add_development_dependency(%q<stale_fish>, ["~> 1.3.0"])
    else
      s.add_dependency(%q<rest-client>, ["~> 1.6.0"])
      s.add_dependency(%q<happymapper>, [">= 0.3.2"])
      s.add_dependency(%q<builder>, [">= 0"])
      s.add_dependency(%q<nokogiri>, ["~> 1.4"])
      s.add_dependency(%q<rest-client>, ["~> 1.6.0"])
      s.add_dependency(%q<happymapper>, [">= 0.3.2"])
      s.add_dependency(%q<builder>, [">= 0"])
      s.add_dependency(%q<nokogiri>, [">= 1.4.3"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.12"])
      s.add_dependency(%q<jeweler>, [">= 0"])
      s.add_dependency(%q<stale_fish>, ["~> 1.3.0"])
    end
  else
    s.add_dependency(%q<rest-client>, ["~> 1.6.0"])
    s.add_dependency(%q<happymapper>, [">= 0.3.2"])
    s.add_dependency(%q<builder>, [">= 0"])
    s.add_dependency(%q<nokogiri>, ["~> 1.4"])
    s.add_dependency(%q<rest-client>, ["~> 1.6.0"])
    s.add_dependency(%q<happymapper>, [">= 0.3.2"])
    s.add_dependency(%q<builder>, [">= 0"])
    s.add_dependency(%q<nokogiri>, [">= 1.4.3"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.12"])
    s.add_dependency(%q<jeweler>, [">= 0"])
    s.add_dependency(%q<stale_fish>, ["~> 1.3.0"])
  end
end
