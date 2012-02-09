# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "arel"
  s.version = "2.0.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Aaron Patterson", "Bryan Halmkamp", "Emilio Tagua", "Nick Kallen"]
  s.date = "2011-05-17"
  s.description = "Arel is a Relational Algebra for Ruby. It 1) simplifies the generation complex of SQL queries and it 2) adapts to various RDBMS systems. It is intended to be a framework framework; that is, you can build your own ORM with it, focusing on innovative object and collection modeling as opposed to database compatibility and query generation."
  s.email = ["aaron@tenderlovemaking.com", "bryan@brynary.com", "miloops@gmail.com", "nick@example.org"]
  s.extra_rdoc_files = ["History.txt", "MIT-LICENSE.txt", "Manifest.txt", "README.markdown"]
  s.files = ["History.txt", "MIT-LICENSE.txt", "Manifest.txt", "README.markdown"]
  s.homepage = "http://github.com/rails/arel"
  s.rdoc_options = ["--main", "README.markdown"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "arel"
  s.rubygems_version = "1.8.15"
  s.summary = "Arel is a Relational Algebra for Ruby"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<minitest>, [">= 2.0.2"])
      s.add_development_dependency(%q<hoe>, [">= 2.1.0"])
      s.add_development_dependency(%q<minitest>, [">= 1.6.0"])
      s.add_development_dependency(%q<hoe>, [">= 2.9.1"])
    else
      s.add_dependency(%q<minitest>, [">= 2.0.2"])
      s.add_dependency(%q<hoe>, [">= 2.1.0"])
      s.add_dependency(%q<minitest>, [">= 1.6.0"])
      s.add_dependency(%q<hoe>, [">= 2.9.1"])
    end
  else
    s.add_dependency(%q<minitest>, [">= 2.0.2"])
    s.add_dependency(%q<hoe>, [">= 2.1.0"])
    s.add_dependency(%q<minitest>, [">= 1.6.0"])
    s.add_dependency(%q<hoe>, [">= 2.9.1"])
  end
end
