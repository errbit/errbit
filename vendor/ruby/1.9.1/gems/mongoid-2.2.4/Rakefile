require "bundler"
Bundler.setup

require "rake"
require "rdoc/task"
require "rspec"
require "rspec/core/rake_task"

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "mongoid/version"

task :gem => :build
task :build do
  system "gem build mongoid.gemspec"
end

task :install => :build do
  system "sudo gem install mongoid-#{Mongoid::VERSION}.gem"
end

task :release => :build do
  system "git tag -a v#{Mongoid::VERSION} -m 'Tagging #{Mongoid::VERSION}'"
  system "git push --tags"
  system "gem push mongoid-#{Mongoid::VERSION}.gem"
end

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end

RSpec::Core::RakeTask.new("spec:unit") do |spec|
  spec.pattern = "spec/unit/**/*_spec.rb"
end

RSpec::Core::RakeTask.new("spec:functional") do |spec|
  spec.pattern = "spec/functional/**/*_spec.rb"
end

RSpec::Core::RakeTask.new('spec:progress') do |spec|
  spec.rspec_opts = %w(--format progress)
  spec.pattern = "spec/**/*_spec.rb"
end

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title = "mongoid #{Mongoid::VERSION}"
  rdoc.rdoc_files.include("README*")
  rdoc.rdoc_files.include("CHANGELOG*")
  rdoc.rdoc_files.include("lib/**/*.rb")
end

task :default => [ "spec:functional", "spec:unit" ]
