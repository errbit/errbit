$:.unshift("lib")
require 'rubygems'
require 'rake'

$:.unshift(File.expand_path('lib', File.dirname(__FILE__)))
require 'crack'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "crack"
    gem.summary = %Q{Really simple JSON and XML parsing, ripped from Merb and Rails.}
    gem.email = "nunemaker@gmail.com"
    gem.homepage = "http://github.com/jnunemaker/crack"
    gem.authors = ["John Nunemaker", "Wynn Netherland"]
    gem.rubyforge_project = 'crack'
    gem.version = Crack::VERSION
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = false
end

task :default => :test
