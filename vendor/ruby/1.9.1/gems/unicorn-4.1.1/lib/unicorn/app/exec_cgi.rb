# -*- encoding: binary -*-
# :enddoc:
require 'unicorn'

module Unicorn::App

  # This class is highly experimental (even more so than the rest of Unicorn)
  # and has never run anything other than cgit.
  class ExecCgi < Struct.new(:args)

    CHUNK_SIZE = 16384
    PASS_VARS = %w(
      CONTENT_LENGTH
      CONTENT_TYPE
      GATEWAY_INTERFACE
      AUTH_TYPE
      PATH_INFO
      PATH_TRANSLATED
      QUERY_STRING
      REMOTE_ADDR
      REMOTE_HOST
      REMOTE_IDENT
      REMOTE_USER
      REQUEST_METHOD
      SERVER_NAME
      SERVER_PORT
      SERVER_PROTOCOL
      SERVER_SOFTWARE
    ).map { |x| x.freeze } # frozen strings are faster for Hash assignments

    class Body < Unicorn::TmpIO
      def body_offset=(n)
        sysseek(@body_offset = n)
      end

      def each
        sysseek @body_offset
        # don't use a preallocated buffer for sysread since we can't
        # guarantee an actual socket is consuming the yielded string
        # (or if somebody is pushing to an array for eventual concatenation
        begin
          yield sysread(CHUNK_SIZE)
        rescue EOFError
          break
        end while true
      end
    end

    # Intializes the app, example of usage in a config.ru
    #   map "/cgit" do
    #     run Unicorn::App::ExecCgi.new("/path/to/cgit.cgi")
    #   end
    def initialize(*args)
      self.args = args
      first = args[0] or
        raise ArgumentError, "need path to executable"
      first[0] == ?/ or args[0] = ::File.expand_path(first)
      File.executable?(args[0]) or
        raise ArgumentError, "#{args[0]} is not executable"
    end

    # Calls the app
    def call(env)
      out, err = Body.new, Unicorn::TmpIO.new
      inp = force_file_input(env)
      pid = fork { run_child(inp, out, err, env) }
      inp.close
      pid, status = Process.waitpid2(pid)
      write_errors(env, err, status) if err.stat.size > 0
      err.close

      return parse_output!(out) if status.success?
      out.close
      [ 500, { 'Content-Length' => '0', 'Content-Type' => 'text/plain' }, [] ]
    end

    private

    def run_child(inp, out, err, env)
      PASS_VARS.each do |key|
        val = env[key] or next
        ENV[key] = val
      end
      ENV['SCRIPT_NAME'] = args[0]
      ENV['GATEWAY_INTERFACE'] = 'CGI/1.1'
      env.keys.grep(/^HTTP_/) { |key| ENV[key] = env[key] }

      $stdin.reopen(inp)
      $stdout.reopen(out)
      $stderr.reopen(err)
      exec(*args)
    end

    # Extracts headers from CGI out, will change the offset of out.
    # This returns a standard Rack-compatible return value:
    #   [ 200, HeadersHash, body ]
    def parse_output!(out)
      size = out.stat.size
      out.sysseek(0)
      head = out.sysread(CHUNK_SIZE)
      offset = 2
      head, body = head.split(/\n\n/, 2)
      if body.nil?
        head, body = head.split(/\r\n\r\n/, 2)
        offset = 4
      end
      offset += head.length
      out.body_offset = offset
      size -= offset
      prev = nil
      headers = Rack::Utils::HeaderHash.new
      head.split(/\r?\n/).each do |line|
        case line
        when /^([A-Za-z0-9-]+):\s*(.*)$/ then headers[prev = $1] = $2
        when /^[ \t]/ then headers[prev] << "\n#{line}" if prev
        end
      end
      status = headers.delete("Status") || 200
      headers['Content-Length'] = size.to_s
      [ status, headers, out ]
    end

    # ensures rack.input is a file handle that we can redirect stdin to
    def force_file_input(env)
      inp = env['rack.input']
      # inp could be a StringIO or StringIO-like object
      if inp.respond_to?(:size) && inp.size == 0
        ::File.open('/dev/null', 'rb')
      else
        tmp = Unicorn::TmpIO.new

        buf = inp.read(CHUNK_SIZE)
        begin
          tmp.syswrite(buf)
        end while inp.read(CHUNK_SIZE, buf)
        tmp.sysseek(0)
        tmp
      end
    end

    # rack.errors this may not be an IO object, so we couldn't
    # just redirect the CGI executable to that earlier.
    def write_errors(env, err, status)
      err.seek(0)
      dst = env['rack.errors']
      pid = status.pid
      dst.write("#{pid}: #{args.inspect} status=#{status} stderr:\n")
      err.each_line { |line| dst.write("#{pid}: #{line}") }
      dst.flush
    end

  end

end
