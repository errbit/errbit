# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "octokit"
  s.version = "0.6.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.authors = ["Wynn Netherland", "Adam Stacoviak", "Erik Michaels-Ober"]
  s.date = "2011-07-02"
  s.description = "Simple wrapper for the GitHub API v2"
  s.email = ["wynn.netherland@gmail.com", "adam@stacoviak.com", "sferik@gmail.com"]
  s.homepage = "https://github.com/pengwynn/octokit"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.15"
  s.summary = "Wrapper for the GitHub API"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<addressable>, ["~> 2.2.6"])
      s.add_runtime_dependency(%q<faraday>, ["~> 0.7.3"])
      s.add_runtime_dependency(%q<faraday_middleware>, ["~> 0.7.0.rc1"])
      s.add_runtime_dependency(%q<hashie>, ["~> 1.0.0"])
      s.add_runtime_dependency(%q<multi_json>, ["~> 1.0.2"])
      s.add_development_dependency(%q<ZenTest>, ["~> 4.5"])
      s.add_development_dependency(%q<nokogiri>, ["~> 1.4"])
      s.add_development_dependency(%q<rake>, ["~> 0.9"])
      s.add_development_dependency(%q<rspec>, ["~> 2.6"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.4"])
      s.add_development_dependency(%q<webmock>, ["~> 1.6"])
      s.add_development_dependency(%q<yajl-ruby>, ["~> 0.8"])
      s.add_development_dependency(%q<yard>, ["~> 0.7"])
    else
      s.add_dependency(%q<addressable>, ["~> 2.2.6"])
      s.add_dependency(%q<faraday>, ["~> 0.7.3"])
      s.add_dependency(%q<faraday_middleware>, ["~> 0.7.0.rc1"])
      s.add_dependency(%q<hashie>, ["~> 1.0.0"])
      s.add_dependency(%q<multi_json>, ["~> 1.0.2"])
      s.add_dependency(%q<ZenTest>, ["~> 4.5"])
      s.add_dependency(%q<nokogiri>, ["~> 1.4"])
      s.add_dependency(%q<rake>, ["~> 0.9"])
      s.add_dependency(%q<rspec>, ["~> 2.6"])
      s.add_dependency(%q<simplecov>, ["~> 0.4"])
      s.add_dependency(%q<webmock>, ["~> 1.6"])
      s.add_dependency(%q<yajl-ruby>, ["~> 0.8"])
      s.add_dependency(%q<yard>, ["~> 0.7"])
    end
  else
    s.add_dependency(%q<addressable>, ["~> 2.2.6"])
    s.add_dependency(%q<faraday>, ["~> 0.7.3"])
    s.add_dependency(%q<faraday_middleware>, ["~> 0.7.0.rc1"])
    s.add_dependency(%q<hashie>, ["~> 1.0.0"])
    s.add_dependency(%q<multi_json>, ["~> 1.0.2"])
    s.add_dependency(%q<ZenTest>, ["~> 4.5"])
    s.add_dependency(%q<nokogiri>, ["~> 1.4"])
    s.add_dependency(%q<rake>, ["~> 0.9"])
    s.add_dependency(%q<rspec>, ["~> 2.6"])
    s.add_dependency(%q<simplecov>, ["~> 0.4"])
    s.add_dependency(%q<webmock>, ["~> 1.6"])
    s.add_dependency(%q<yajl-ruby>, ["~> 0.8"])
    s.add_dependency(%q<yard>, ["~> 0.7"])
  end
end
