# -*- encoding: utf-8 -*-
# stub: hoptoad_notifier 2.4.11 ruby lib

Gem::Specification.new do |s|
  s.name = "hoptoad_notifier".freeze
  s.version = "2.4.11"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["thoughtbot, inc".freeze]
  s.date = "2011-05-26"
  s.email = "support@hoptoadapp.com".freeze
  s.homepage = "http://www.hoptoadapp.com".freeze
  s.rubygems_version = "3.3.17".freeze
  s.summary = "Send your application errors to our hosted service and reclaim your inbox.".freeze

  s.installed_by_version = "3.3.17" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<builder>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0"])
    s.add_development_dependency(%q<activerecord>.freeze, [">= 0"])
    s.add_development_dependency(%q<actionpack>.freeze, [">= 0"])
    s.add_development_dependency(%q<bourne>.freeze, [">= 0"])
    s.add_development_dependency(%q<nokogiri>.freeze, [">= 0"])
    s.add_development_dependency(%q<shoulda>.freeze, [">= 0"])
  else
    s.add_dependency(%q<builder>.freeze, [">= 0"])
    s.add_dependency(%q<activesupport>.freeze, [">= 0"])
    s.add_dependency(%q<activerecord>.freeze, [">= 0"])
    s.add_dependency(%q<actionpack>.freeze, [">= 0"])
    s.add_dependency(%q<bourne>.freeze, [">= 0"])
    s.add_dependency(%q<nokogiri>.freeze, [">= 0"])
    s.add_dependency(%q<shoulda>.freeze, [">= 0"])
  end
end
