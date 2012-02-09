Gem::Specification.new do |s|
  s.name     = "actionmailer_inline_css"
  s.version  = "1.3.1"
  s.date = Time.now.strftime('%Y-%m-%d')
  s.summary  = "Always send HTML e-mails with inline CSS, using the 'premailer' gem"
  s.email    = "nathan.f77@gmail.com"
  s.homepage = "http://premailer.dialect.ca/"
  s.description = "Module for ActionMailer to improve the rendering of HTML emails by using the 'premailer' gem, which inlines CSS and makes relative links absolute."
  s.has_rdoc = false
  s.author  = "Nathan Broadbent"
  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency('actionmailer', '>= 3.0.0')
  s.add_dependency('premailer',    '>= 1.7.1')
  s.add_dependency('nokogiri',     '>= 1.4.4')
  s.add_development_dependency('mocha', '>= 0.10.0')
end

