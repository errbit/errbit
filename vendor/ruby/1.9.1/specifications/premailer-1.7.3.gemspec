# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "premailer"
  s.version = "1.7.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Alex Dunae"]
  s.date = "2011-09-08"
  s.description = "Improve the rendering of HTML emails by making CSS inline, converting links and warning about unsupported code."
  s.email = "code@dunae.ca"
  s.executables = ["premailer"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["bin/premailer", "README.rdoc"]
  s.homepage = "http://premailer.dialect.ca/"
  s.rdoc_options = ["--all", "--inline-source", "--line-numbers", "--charset", "utf-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.15"
  s.summary = "Preflight for HTML e-mail."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<css_parser>, [">= 1.1.9"])
      s.add_runtime_dependency(%q<htmlentities>, [">= 4.0.0"])
      s.add_development_dependency(%q<hpricot>, [">= 0.8.3"])
      s.add_development_dependency(%q<nokogiri>, [">= 1.4.4"])
      s.add_development_dependency(%q<rake>, ["!= 0.9.0", "~> 0.8"])
      s.add_development_dependency(%q<rdoc>, [">= 2.4.2"])
    else
      s.add_dependency(%q<css_parser>, [">= 1.1.9"])
      s.add_dependency(%q<htmlentities>, [">= 4.0.0"])
      s.add_dependency(%q<hpricot>, [">= 0.8.3"])
      s.add_dependency(%q<nokogiri>, [">= 1.4.4"])
      s.add_dependency(%q<rake>, ["!= 0.9.0", "~> 0.8"])
      s.add_dependency(%q<rdoc>, [">= 2.4.2"])
    end
  else
    s.add_dependency(%q<css_parser>, [">= 1.1.9"])
    s.add_dependency(%q<htmlentities>, [">= 4.0.0"])
    s.add_dependency(%q<hpricot>, [">= 0.8.3"])
    s.add_dependency(%q<nokogiri>, [">= 1.4.4"])
    s.add_dependency(%q<rake>, ["!= 0.9.0", "~> 0.8"])
    s.add_dependency(%q<rdoc>, [">= 2.4.2"])
  end
end
