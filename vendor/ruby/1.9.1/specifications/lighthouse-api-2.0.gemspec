# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "lighthouse-api"
  s.version = "2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Rick Olson", "Justin Palmer"]
  s.date = "2010-10-04"
  s.description = "Ruby API wrapper for Lighthouse - http://lighthouseapp.com"
  s.email = ["justin@entp.com"]
  s.extra_rdoc_files = ["LICENSE"]
  s.files = ["LICENSE"]
  s.homepage = "http://lighthouseapp.com/api"
  s.rdoc_options = ["--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "lighthouse"
  s.rubygems_version = "1.8.15"
  s.summary = "Ruby API wrapper for Lighthouse - http://lighthouseapp.com"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 3.0.0"])
      s.add_runtime_dependency(%q<activeresource>, [">= 3.0.0"])
    else
      s.add_dependency(%q<activesupport>, [">= 3.0.0"])
      s.add_dependency(%q<activeresource>, [">= 3.0.0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 3.0.0"])
    s.add_dependency(%q<activeresource>, [">= 3.0.0"])
  end
end
