#!/usr/bin/env ruby

require "rubygems"
require "rake/extensiontask"
require "rake/testtask"
require "rubygems/package_task"
require "rdoc/task"
require "yaml"

GEM_NAME = "libxml-ruby"
SO_NAME  = "libxml_ruby"

# Read the spec file
spec = Gem::Specification.load("#{GEM_NAME}.gemspec")

# Setup compile tasks
Rake::ExtensionTask.new do |ext|
  ext.gem_spec = spec
  ext.name = SO_NAME
  ext.ext_dir = "ext/libxml"
  ext.lib_dir = "lib/#{RUBY_VERSION.sub(/\.\d$/, '')}"
  ext.config_options << "--with-xml2-include=C:/MinGW/local/include/libxml2"
  ext.config_options << "--with-zlib-dir=C:/MinGW/local"
end

# Setup generic gem
Gem::PackageTask.new(spec) do |pkg|
  pkg.package_dir = 'pkg'
  pkg.need_tar    = false
end

# Setup Windows Gem
if RUBY_PLATFORM.match(/win32|mingw32/)
  binaries = (FileList['lib/**/*.so',
                       'lib/**/*dll'])

  # Windows specification
  win_spec = spec.clone
  win_spec.platform = Gem::Platform::CURRENT
  win_spec.files += binaries.to_a
  win_spec.instance_variable_set(:@cache_file, nil)

  # Unset extensions
  win_spec.extensions = nil

  # Rake task to build the windows package
  Gem::PackageTask.new(win_spec) do |pkg|
    pkg.package_dir = 'pkg'
    pkg.need_tar = false
  end
end

# RDoc Task
desc "Generate rdoc documentation"
RDoc::Task.new("rdoc") do |rdoc|
  rdoc.rdoc_dir = 'doc/libxml-ruby/rdoc'
  rdoc.title    = "LibXML"
  # Show source inline with line numbers
  rdoc.options << "--line-numbers"
  # Make the readme file the start page for the generated html
  rdoc.main = 'README.rdoc'
  rdoc.rdoc_files.include('doc/*.rdoc',
                          'ext/**/libxml.c',
                          'ext/**/ruby_xml.c',
                          'ext/**/*.c',
                          'lib/**/*.rb',
                          'README.rdoc',
                          'HISTORY',
                          'LICENSE')
end

# Test Task
Rake::TestTask.new do |t|
  t.libs << "test"
  t.verbose = true
end

desc "Build docs, and publish the website"
task :publish_with_docs => [:rdoc, :publish]