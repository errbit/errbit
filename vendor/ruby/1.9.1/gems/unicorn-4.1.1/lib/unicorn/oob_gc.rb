# -*- encoding: binary -*-

# Runs GC after requests, after closing the client socket and
# before attempting to accept more connections.
#
# This shouldn't hurt overall performance as long as the server cluster
# is at <50% CPU capacity, and improves the performance of most memory
# intensive requests.  This serves to improve _client-visible_
# performance (possibly at the cost of overall performance).
#
# Increasing the number of +worker_processes+ may be necessary to
# improve average client response times because some of your workers
# will be busy doing GC and unable to service clients.  Think of
# using more workers with this module as a poor man's concurrent GC.
#
# We'll call GC after each request is been written out to the socket, so
# the client never sees the extra GC hit it.
#
# This middleware is _only_ effective for applications that use a lot
# of memory, and will hurt simpler apps/endpoints that can process
# multiple requests before incurring GC.
#
# This middleware is only designed to work with unicorn, as it harms
# performance with keepalive-enabled servers.
#
# Example (in config.ru):
#
#     require 'unicorn/oob_gc'
#
#     # GC ever two requests that hit /expensive/foo or /more_expensive/foo
#     # in your app.  By default, this will GC once every 5 requests
#     # for all endpoints in your app
#     use Unicorn::OobGC, 2, %r{\A/(?:expensive/foo|more_expensive/foo)}
#
# Feedback from users of early implementations of this module:
# * http://comments.gmane.org/gmane.comp.lang.ruby.unicorn.general/486
# * http://article.gmane.org/gmane.comp.lang.ruby.unicorn.general/596
module Unicorn::OobGC

  # this pretends to be Rack middleware because it used to be
  # But we need to hook into unicorn internals so we need to close
  # the socket before clearing the request env.
  #
  # +interval+ is the number of requests matching the +path+ regular
  # expression before invoking GC.
  def self.new(app, interval = 5, path = %r{\A/})
    @@nr = interval
    self.const_set :OOBGC_PATH, path
    self.const_set :OOBGC_INTERVAL, interval
    ObjectSpace.each_object(Unicorn::HttpServer) do |s|
      s.extend(self)
      self.const_set :OOBGC_ENV, s.instance_variable_get(:@request).env
    end
    app # pretend to be Rack middleware since it was in the past
  end

  #:stopdoc:
  PATH_INFO = "PATH_INFO"
  def process_client(client)
    super(client) # Unicorn::HttpServer#process_client
    if OOBGC_PATH =~ OOBGC_ENV[PATH_INFO] && ((@@nr -= 1) <= 0)
      @@nr = OOBGC_INTERVAL
      OOBGC_ENV.clear
      GC.start
    end
  end

  # :startdoc:
end
