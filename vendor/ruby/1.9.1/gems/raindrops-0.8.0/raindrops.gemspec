# -*- encoding: binary -*-
ENV["VERSION"] or abort "VERSION= must be specified"
manifest = File.readlines('.manifest').map! { |x| x.chomp! }
test_files = manifest.grep(%r{\Atest/test_.*\.rb\z})
require 'wrongdoc'
extend Wrongdoc::Gemspec
name, summary, title = readme_metadata

Gem::Specification.new do |s|
  s.name = %q{raindrops}
  s.version = ENV["VERSION"].dup

  s.authors = ["raindrops hackers"]
  s.date = Time.now.utc.strftime('%Y-%m-%d')
  s.description = readme_description
  s.email = %q{raindrops@librelist.org}
  s.extensions = %w(ext/raindrops/extconf.rb)
  s.extra_rdoc_files = extra_rdoc_files(manifest)
  s.files = manifest
  s.homepage = Wrongdoc.config[:rdoc_url]
  s.summary = summary
  s.rdoc_options = rdoc_options
  s.rubyforge_project = %q{rainbows}
  s.test_files = test_files
  s.add_development_dependency('bundler', '~> 1.0.10')

  # s.licenses = %w(LGPLv3) # accessor not compatible with older RubyGems
end
