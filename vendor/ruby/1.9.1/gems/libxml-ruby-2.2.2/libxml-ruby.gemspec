# encoding: utf-8

# Determine the current version of the software
version = File.read('ext/libxml/ruby_xml_version.h').match(/\s*RUBY_LIBXML_VERSION\s*['"](\d.+)['"]/)[1]

Gem::Specification.new do |spec|
  spec.name        = 'libxml-ruby'
  spec.version     = version
  spec.homepage    = 'http://xml4r.github.com/libxml-ruby'
  spec.summary     = 'Ruby Bindings for LibXML2'
  spec.description = <<-EOS
    The Libxml-Ruby project provides Ruby language bindings for the GNOME
    Libxml2 XML toolkit. It is free software, released under the MIT License.
    Libxml-ruby's primary advantage over REXML is performance - if speed
    is your need, these are good libraries to consider, as demonstrated
    by the informal benchmark below.
  EOS
  spec.authors = ['Ross Bamform', 'Wai-Sun Chia', 'Sean Chittenden',
                  'Dan Janwoski', 'Anurag Priyam', 'Charlie Savage']
  spec.platform = Gem::Platform::RUBY
  spec.bindir = "bin"
  spec.extensions = ["ext/libxml/extconf.rb"]
  spec.files = Dir.glob(['HISTORY',
                         'LICENSE',
                         'libxml-ruby.gemspec',
                         'MANIFEST',
                         'Rakefile',
                         'README.rdoc',
                         'setup.rb',
                         'ext/libxml/*.def',
                         'ext/libxml/*.h',
                         'ext/libxml/*.c',
                         'ext/libxml/*.rb',
                         'ext/vc/*.sln',
                         'ext/vc/*.vcprojx',
                         'lib/**/*.rb',
                         'script/**/*',
                         'test/**/*'])
  spec.test_files = Dir.glob("test/tc_*.rb")
  spec.required_ruby_version = '>= 1.8.6'
  spec.date = DateTime.now
end