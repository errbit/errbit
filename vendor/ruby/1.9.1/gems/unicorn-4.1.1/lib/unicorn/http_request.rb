# -*- encoding: binary -*-
# :enddoc:
# no stable API here
require 'unicorn_http'

# TODO: remove redundant names
Unicorn.const_set(:HttpRequest, Unicorn::HttpParser)
class Unicorn::HttpParser

  # default parameters we merge into the request env for Rack handlers
  DEFAULTS = {
    "rack.errors" => $stderr,
    "rack.multiprocess" => true,
    "rack.multithread" => false,
    "rack.run_once" => false,
    "rack.version" => [1, 1],
    "SCRIPT_NAME" => "",

    # this is not in the Rack spec, but some apps may rely on it
    "SERVER_SOFTWARE" => "Unicorn #{Unicorn::Const::UNICORN_VERSION}"
  }

  NULL_IO = StringIO.new("")

  # :stopdoc:
  # A frozen format for this is about 15% faster
  REMOTE_ADDR = 'REMOTE_ADDR'.freeze
  RACK_INPUT = 'rack.input'.freeze
  @@input_class = Unicorn::TeeInput

  def self.input_class
    @@input_class
  end

  def self.input_class=(klass)
    @@input_class = klass
  end
  # :startdoc:

  # Does the majority of the IO processing.  It has been written in
  # Ruby using about 8 different IO processing strategies.
  #
  # It is currently carefully constructed to make sure that it gets
  # the best possible performance for the common case: GET requests
  # that are fully complete after a single read(2)
  #
  # Anyone who thinks they can make it faster is more than welcome to
  # take a crack at it.
  #
  # returns an environment hash suitable for Rack if successful
  # This does minimal exception trapping and it is up to the caller
  # to handle any socket errors (e.g. user aborted upload).
  def read(socket)
    clear
    e = env

    # From http://www.ietf.org/rfc/rfc3875:
    # "Script authors should be aware that the REMOTE_ADDR and
    #  REMOTE_HOST meta-variables (see sections 4.1.8 and 4.1.9)
    #  may not identify the ultimate source of the request.  They
    #  identify the client for the immediate request to the server;
    #  that client may be a proxy, gateway, or other intermediary
    #  acting on behalf of the actual source client."
    e[REMOTE_ADDR] = socket.kgio_addr

    # short circuit the common case with small GET requests first
    socket.kgio_read!(16384, buf)
    if parse.nil?
      # Parser is not done, queue up more data to read and continue parsing
      # an Exception thrown from the parser will throw us out of the loop
      false until add_parse(socket.kgio_read!(16384))
    end
    e[RACK_INPUT] = 0 == content_length ?
                    NULL_IO : @@input_class.new(socket, self)
    e.merge!(DEFAULTS)
  end
end
