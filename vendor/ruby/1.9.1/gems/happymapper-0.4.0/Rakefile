require 'rubygems'
require 'bundler/setup'

require 'rake'
require 'spec/rake/spectask'
require File.expand_path('../lib/happymapper/version', __FILE__)

Spec::Rake::SpecTask.new do |t|
  t.ruby_opts << '-rubygems'
  t.verbose = true
end
task :default => :spec

desc 'Builds the gem'
task :build do
  sh "gem build happymapper.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  sh "gem install happymapper-#{HappyMapper::Version}"
end

desc 'Tags version, pushes to remote, and pushes gem'
task :release => :build do
  sh "git tag v#{HappyMapper::Version}"
  sh "git push origin master"
  sh "git push origin v#{HappyMapper::Version}"
  sh "gem push happymapper-#{HappyMapper::Version}.gem"
end

desc 'Upload website files to rubyforge'
task :website do
  sh %{rsync -av website/ jnunemaker@rubyforge.org:/var/www/gforge-projects/happymapper}
end
