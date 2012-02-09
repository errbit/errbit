require 'rubygems'
require 'rake'
# require 'jeweler'

begin
  require 'ad_agency'
  Jeweler::Tasks.new do |gem|
    gem.name = "ri_cal"
    gem.summary = %Q{a new implementation of RFC2445 in Ruby}
    gem.description = %Q{A new Ruby implementation of RFC2445 iCalendar.

The existing Ruby iCalendar libraries (e.g. icalendar, vpim) provide for parsing and generating icalendar files,
but do not support important things like enumerating occurrences of repeating events.

This is a clean-slate implementation of RFC2445.

A Google group for discussion of this library has been set up http://groups.google.com/group/rical_gem
    }
    gem.email = "rick.denatale@gmail.com"
    gem.homepage = "http://github.com/rubyredrick/ri_cal"
    gem.authors = ["Rick DeNatale"]
    ['.gitignore', 'performance_data/*', 'sample_ical_files/*', 'website/*', 'config/website.yml'].each do |excl|
      gem.files.exclude excl
    end
    gem.extra_rdoc_files.include %w{History.txt copyrights.txt}
    # gem.add_development_dependency "thoughtbot-shoulda", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
  Jeweler::AdAgencyTasks.new
# rescue LoadError => ex
#   puts ex
#   puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

Dir['tasks/**/*.rake'].each { |t| load t }

task :default => [:"spec:with_tzinfo_gem", :"spec:with_active_support"]


require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ri_cal #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
