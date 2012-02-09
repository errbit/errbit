# This is the exact config that powers http://raindrops-demo.bogomips.org/
# This is used with zbatery.conf.rb
#
# zbatery -c zbatery.conf.ru watcher_demo.ru -E none
require "raindrops"
use Raindrops::Middleware
listeners = %w(
  0.0.0.0:9418
  0.0.0.0:80
  /tmp/.raindrops
  /tmp/.r
)
run Raindrops::Watcher.new :listeners => listeners
