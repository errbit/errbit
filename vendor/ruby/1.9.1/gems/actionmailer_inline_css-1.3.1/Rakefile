#!/usr/bin/env rake
$:.unshift File.expand_path('../lib', __FILE__)

require 'rake'
require 'rake/testtask'
require 'rake/packagetask'
require 'rubygems/package_task'

def gemspec
 @gemspec ||= begin
   file = File.expand_path('../actionmailer_inline_css.gemspec', __FILE__)
   eval(File.read(file), binding, file)
 end
end

Gem::PackageTask.new(gemspec) do |pkg|
  pkg.need_tar = true
end


desc "Default Task"
task :default => [ :test ]

# Run the unit tests
Rake::TestTask.new { |t|
  t.libs << "test"
  t.pattern = 'test/**/*_test.rb'
}

