ENV["VERSION"] or abort "VERSION= must be specified"
manifest = File.readlines('.manifest').map! { |x| x.chomp! }
require 'wrongdoc'
extend Wrongdoc::Gemspec
name, summary, title = readme_metadata

Gem::Specification.new do |s|
  s.name = %q{kgio}
  s.version = ENV["VERSION"].dup
  s.homepage = Wrongdoc.config[:rdoc_url]
  s.authors = ["#{name} hackers"]
  s.date = Time.now.utc.strftime('%Y-%m-%d')
  s.description = readme_description
  s.email = %q{kgio@librelist.org}
  s.extra_rdoc_files = extra_rdoc_files(manifest)
  s.files = manifest
  s.rdoc_options = rdoc_options
  s.rubyforge_project = %q{rainbows}
  s.summary = summary
  s.test_files = Dir['test/test_*.rb']
  s.extensions = %w(ext/kgio/extconf.rb)

  s.add_development_dependency('wrongdoc', '~> 1.5')
  s.add_development_dependency('strace_me', '~> 1.0')

  # s.license = %w(LGPL) # disabled for compatibility with older RubyGems
end
