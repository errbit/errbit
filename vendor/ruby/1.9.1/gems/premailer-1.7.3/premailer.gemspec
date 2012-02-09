Gem::Specification.new do |s|
  s.name     = "premailer"
  s.version  = "1.7.3"
  s.date = Time.now.strftime('%Y-%m-%d')
  s.summary  = "Preflight for HTML e-mail."
  s.email    = "code@dunae.ca"
  s.homepage = "http://premailer.dialect.ca/"
  s.description = "Improve the rendering of HTML emails by making CSS inline, converting links and warning about unsupported code."
  s.has_rdoc = true
  s.author  = "Alex Dunae"
  s.rdoc_options << '--all' << '--inline-source' << '--line-numbers' << '--charset' << 'utf-8'
  s.extra_rdoc_files = ["README.rdoc"]
  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.add_dependency('css_parser', '>= 1.1.9')
  s.add_dependency('htmlentities', '>= 4.0.0')
  s.add_development_dependency('hpricot', '>= 0.8.3')
  s.add_development_dependency('nokogiri', '>= 1.4.4')
  s.add_development_dependency('rake', ['~> 0.8',  '!= 0.9.0'])
  s.add_development_dependency('rdoc', '>= 2.4.2')
end
