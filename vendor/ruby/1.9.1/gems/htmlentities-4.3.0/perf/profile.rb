# encoding: UTF-8
$KCODE = 'u' unless "1.9".respond_to?(:encoding)

require File.join(File.dirname(__FILE__), "performance")
require "profiler"

job = HTMLEntitiesJob.new

puts "Encoding"
Profiler__::start_profile
job.encode(1)
Profiler__::print_profile($stdout)

puts "Decoding"
Profiler__::start_profile
job.decode(1)
Profiler__::print_profile($stdout)
