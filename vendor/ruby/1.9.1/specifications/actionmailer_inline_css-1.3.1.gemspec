# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "actionmailer_inline_css"
  s.version = "1.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nathan Broadbent"]
  s.date = "2011-09-30"
  s.description = "Module for ActionMailer to improve the rendering of HTML emails by using the 'premailer' gem, which inlines CSS and makes relative links absolute."
  s.email = "nathan.f77@gmail.com"
  s.homepage = "http://premailer.dialect.ca/"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.15"
  s.summary = "Always send HTML e-mails with inline CSS, using the 'premailer' gem"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<actionmailer>, [">= 3.0.0"])
      s.add_runtime_dependency(%q<premailer>, [">= 1.7.1"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 1.4.4"])
      s.add_development_dependency(%q<mocha>, [">= 0.10.0"])
    else
      s.add_dependency(%q<actionmailer>, [">= 3.0.0"])
      s.add_dependency(%q<premailer>, [">= 1.7.1"])
      s.add_dependency(%q<nokogiri>, [">= 1.4.4"])
      s.add_dependency(%q<mocha>, [">= 0.10.0"])
    end
  else
    s.add_dependency(%q<actionmailer>, [">= 3.0.0"])
    s.add_dependency(%q<premailer>, [">= 1.7.1"])
    s.add_dependency(%q<nokogiri>, [">= 1.4.4"])
    s.add_dependency(%q<mocha>, [">= 0.10.0"])
  end
end
