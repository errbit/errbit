Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'mongoid_rails_migrations'
  s.version     = '0.0.14'
  s.summary     = 'Data migrations for Mongoid in Active Record style, minus column input.'
  s.description = 'Migrations for the migrator.'

  # only tested with 1.9.1, but let's go for it
  s.required_ruby_version     = '>= 1.8.6'
  s.required_rubygems_version = ">= 1.3.6"

  s.author            = 'Alan Da Costa'
  s.email             = 'alandacosta@gmail.com.com'
  s.date              = %q{2010-05-12}
  s.homepage          = 'http://github.com/adacosta/mongoid_rails_migrations'
  
  s.require_paths = ["lib"]
  s.files         = Dir['.gitignore', 'Gemfile', 'Gemfile.lock', 'Rakefile', 'README.rdoc', 'mongoid_rails_migrations.gemspec', 'lib/**/*']
  s.test_files    = Dir['test/**/*']
  s.has_rdoc      = false
  
	rails_version = '>= 3.0.0'
	
  s.add_dependency('bundler', '>= 1.0.0')
  s.add_dependency('rails',  rails_version)
  s.add_dependency('railties',  rails_version)
  s.add_dependency('activesupport',  rails_version)
  s.add_development_dependency( "mongoid", ">= 2.0.0")
end