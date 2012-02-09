require "timeout"
require "socket"
require "uri"
require "heroku/client"
require "heroku/helpers"

class Heroku::Client::Rendezvous
  attr_reader :rendezvous_url, :connect_timeout, :activity_timeout, :input, :output, :on_connect

  def initialize(opts)
    @rendezvous_url = opts[:rendezvous_url]
    @connect_timeout = opts[:connect_timeout]
    @activity_timeout = opts[:activity_timeout]
    @input = opts[:input]
    @output = opts[:output]
  end

  def on_connect(&blk)
    @on_connect = blk if block_given?
    @on_connect
  end

  def start
    uri = URI.parse(rendezvous_url)
    host, port, secret = uri.host, uri.port, uri.path[1..-1]

    ssl_socket = Timeout.timeout(connect_timeout) do
      ssl_context = OpenSSL::SSL::SSLContext.new
      if ((host =~ /heroku\.com$/) && !(ENV["HEROKU_SSL_VERIFY"] == "disable"))
        ssl_context.ca_file = File.expand_path("../../../../data/cacert.pem", __FILE__)
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      tcp_socket = TCPSocket.open(host, port)
      ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
      ssl_socket.connect
      ssl_socket.puts(secret)
      ssl_socket.readline
      ssl_socket
    end

    on_connect.call if on_connect

    readables = [input, ssl_socket].compact

    begin
      loop do
        if o = IO.select(readables, nil, nil, activity_timeout)
          if (input && (o.first.first == input))
            begin
              data = input.readpartial(10000)
            rescue EOFError
              readables.delete(input)
              next
            end
            ssl_socket.write(data)
            ssl_socket.flush
          elsif (o.first.first == ssl_socket)
            begin
              data = ssl_socket.readpartial(10000)
            rescue EOFError
              break
            end
            output.write(data)
          end
        else
          raise(Timeout::Error.new)
        end
      end
    rescue Interrupt
      ssl_socket.write("\003")
      ssl_socket.flush
      retry
    rescue Errno::EIO
    end
  end
end
