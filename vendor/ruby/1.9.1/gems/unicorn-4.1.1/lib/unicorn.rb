# -*- encoding: binary -*-
require 'fcntl'
require 'etc'
require 'stringio'
require 'rack'
require 'kgio'

# :stopdoc:
# Unicorn module containing all of the classes (include C extensions) for
# running a Unicorn web server.  It contains a minimalist HTTP server with just
# enough functionality to service web application requests fast as possible.
# :startdoc:

# \Unicorn exposes very little of an user-visible API and most of its
# internals are subject to change.  \Unicorn is designed to host Rack
# applications, so applications should be written against the Rack SPEC
# and not \Unicorn internals.
module Unicorn

  # Raised inside TeeInput when a client closes the socket inside the
  # application dispatch.  This is always raised with an empty backtrace
  # since there is nothing in the application stack that is responsible
  # for client shutdowns/disconnects.  This exception is visible to Rack
  # applications unless PrereadInput middleware is loaded.
  class ClientShutdown < EOFError
  end

  # :stopdoc:

  # This returns a lambda to pass in as the app, this does not "build" the
  # app (which we defer based on the outcome of "preload_app" in the
  # Unicorn config).  The returned lambda will be called when it is
  # time to build the app.
  def self.builder(ru, op)
    # allow Configurator to parse cli switches embedded in the ru file
    op = Unicorn::Configurator::RACKUP.merge!(:file => ru, :optparse => op)

    # always called after config file parsing, may be called after forking
    lambda do ||
      inner_app = case ru
      when /\.ru$/
        raw = File.read(ru)
        raw.sub!(/^__END__\n.*/, '')
        eval("Rack::Builder.new {(\n#{raw}\n)}.to_app", TOPLEVEL_BINDING, ru)
      else
        require ru
        Object.const_get(File.basename(ru, '.rb').capitalize)
      end

      pp({ :inner_app => inner_app }) if $DEBUG

      # return value, matches rackup defaults based on env
      # Unicorn does not support persistent connections, but Rainbows!
      # and Zbatery both do.  Users accustomed to the Rack::Server default
      # middlewares will need ContentLength/Chunked middlewares.
      case ENV["RACK_ENV"]
      when "development"
        Rack::Builder.new do
          use Rack::ContentLength
          use Rack::Chunked
          use Rack::CommonLogger, $stderr
          use Rack::ShowExceptions
          use Rack::Lint
          run inner_app
        end.to_app
      when "deployment"
        Rack::Builder.new do
          use Rack::ContentLength
          use Rack::Chunked
          use Rack::CommonLogger, $stderr
          run inner_app
        end.to_app
      else
        inner_app
      end
    end
  end

  # returns an array of strings representing TCP listen socket addresses
  # and Unix domain socket paths.  This is useful for use with
  # Raindrops::Middleware under Linux: http://raindrops.bogomips.org/
  def self.listener_names
    Unicorn::HttpServer::LISTENERS.map do |io|
      Unicorn::SocketHelper.sock_name(io)
    end
  end

  def self.log_error(logger, prefix, exc)
    message = exc.message
    message = message.dump if /[[:cntrl:]]/ =~ message
    logger.error "#{prefix}: #{message} (#{exc.class})"
    exc.backtrace.each { |line| logger.error(line) }
  end
  # :startdoc:
end
# :enddoc:
require 'unicorn/const'
require 'unicorn/socket_helper'
require 'unicorn/stream_input'
require 'unicorn/tee_input'
require 'unicorn/http_request'
require 'unicorn/configurator'
require 'unicorn/tmpio'
require 'unicorn/util'
require 'unicorn/http_response'
require 'unicorn/worker'
require 'unicorn/http_server'
