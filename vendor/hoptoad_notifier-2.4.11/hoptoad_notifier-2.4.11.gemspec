# -*- encoding: utf-8 -*-
# stub: hoptoad_notifier 2.4.11 ruby lib

Gem::Specification.new do |s|
  s.name = "hoptoad_notifier".freeze
  s.version = "2.4.11".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["thoughtbot, inc".freeze]
  s.date = "2011-05-26"
  s.email = "support@hoptoadapp.com".freeze
  s.homepage = "http://www.hoptoadapp.com".freeze
  s.rubygems_version = "3.4.22".freeze
  s.summary = "Send your application errors to our hosted service and reclaim your inbox.".freeze

  s.installed_by_version = "3.4.22".freeze if s.respond_to? :installed_by_version

  s.specification_version = 3

  s.add_runtime_dependency(%q<builder>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<activerecord>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<actionpack>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bourne>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<nokogiri>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<shoulda>.freeze, [">= 0".freeze])
end
