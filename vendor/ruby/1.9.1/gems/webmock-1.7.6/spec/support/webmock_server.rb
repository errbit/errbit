require 'webrick'
require 'logger'
require 'singleton'

class WebMockServer
  include Singleton

  attr_reader :port

  def host_with_port
    "localhost:#{port}"
  end

  def concurrent
    unless RUBY_PLATFORM =~ /java/
      @pid = Process.fork do
        yield
      end
    else
      Thread.new { yield }
    end
  end

  def start
    server = WEBrick::GenericServer.new(:Port => 0, :Logger => Logger.new("/dev/null"))
    server.logger.level = 0
    @port = server.config[:Port]

    concurrent do
      ['TERM', 'INT'].each do |signal|
        trap(signal){ server.shutdown }
      end
      server.start do |socket|
        socket.puts <<-EOT.gsub(/^\s+\|/, '')
          |HTTP/1.1 200 OK
          |Date: Fri, 31 Dec 1999 23:59:59 GMT
          |Content-Type: text/html
          |Content-Length: 11
          |
          |hello world
        EOT
      end
    end


    loop do
      begin
        s = TCPSocket.new("localhost", port)
        sleep 0.1
        break
      rescue Errno::ECONNREFUSED
        sleep 0.1
      end
    end
  end

  def stop
    if @pid
      Process.kill('INT', @pid)
    end
  end
end
