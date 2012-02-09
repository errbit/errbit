# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "has_scope/version"

Gem::Specification.new do |s|
  s.name        = "has_scope"
  s.version     = HasScope::VERSION.dup
  s.platform    = Gem::Platform::RUBY
  s.summary     = "Maps controller filters to your resource scopes."
  s.email       = "developers@plataformatec.com.br"
  s.homepage    = "http://github.com/plataformatec/has_scope"
  s.description = "Maps controller filters to your resource scopes"
  s.authors     = ['José Valim']

  s.rubyforge_project = "has_scope"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
end