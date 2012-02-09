# encoding: UTF-8

require './test_helper'

# This is related to bug 8337, complaint is on amd64/fbsd
# unknown if it happens on other amd64/os combos

Process.setrlimit(Process::RLIMIT_NOFILE,10005)

(1..10000).each{|time|
  XML::Document.file(File.join(File.dirname(__FILE__),'ets_test.xml'))
  if time % 100 == 0
    print "\r#{time}"  
    $stdout.flush
  end
}
puts "\n"
