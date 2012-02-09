require "bundler"
Bundler.setup
Bundler::GemHelper.install_tasks

task :build => :raise_if_psych_is_defined

task :raise_if_psych_is_defined do
  if defined?(Psych)
    raise <<-MSG
===============================================================================
Gems compiled in Ruby environments with Psych loaded are incompatible with Ruby
environments that don't have Psych loaded. Try building this gem in Ruby 1.8.7
instead.
===============================================================================
MSG
  end
end

require "rake"
require "yaml"

require "rake/rdoctask"
require "rspec/core/rake_task"
require "rspec/core/version"

begin
  require "cucumber/rake/task"
  Cucumber::Rake::Task.new(:cucumber)
rescue LoadError => e
  puts "unable to load cucumber, some tasks unavailable"
  task :cucumber do
    # no-op
  end
end

desc "Run all examples"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_path = 'bin/rspec'
  t.rspec_opts = %w[--color]
  t.verbose = false
end

namespace :rcov do
  task :cleanup do
    rm_rf 'coverage.data'
  end

  RSpec::Core::RakeTask.new :spec do |t|
    t.rcov = true
    t.rcov_opts =  %[-Ilib -Ispec --exclude "gems/*,features"]
    t.rcov_opts << %[--no-html --aggregate coverage.data]
  end

  if defined?(Cucumber)
    Cucumber::Rake::Task.new :cucumber do |t|
      t.cucumber_opts = %w{--format progress}
      t.rcov = true
      t.rcov_opts =  %[-Ilib -Ispec --exclude "gems/*,features"]
      t.rcov_opts << %[--text-report --sort coverage --aggregate coverage.data]
    end
  else
    task :cucumber do
      # no-op
    end
  end

end

task :rcov => ["rcov:cleanup", "rcov:spec", "rcov:cucumber"]

task :default => [:spec, :cucumber]

task :clobber do
  rm_rf 'pkg'
  rm_rf 'tmp'
  rm_rf 'coverage'
end

desc "Push docs/cukes to relishapp using the relish-client-gem"
task :relish, :version do |t, args|
  raise "rake relish[VERSION]" unless args[:version]
  sh "cp Changelog.md features/"
  sh "relish push rspec/rspec-core:#{args[:version]}"
  sh "rm features/Changelog.md"
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rspec-core #{RSpec::Core::Version::STRING}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

