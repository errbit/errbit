require 'net/http'
require 'net/https'
require 'stringio'
require File.join(File.dirname(__FILE__), 'net_http_response')


module WebMock
  module HttpLibAdapters
    class NetHttpAdapter < HttpLibAdapter
      adapter_for :net_http

      OriginalNetHTTP = Net::HTTP unless const_defined?(:OriginalNetHTTP)
      OriginalNetBufferedIO = Net::BufferedIO unless const_defined?(:OriginalNetBufferedIO)

      def self.enable!
        Net.send(:remove_const, :BufferedIO)
        Net.send(:remove_const, :HTTP)
        Net.send(:remove_const, :HTTPSession)
        Net.send(:const_set, :HTTP, @webMockNetHTTP)
        Net.send(:const_set, :HTTPSession, @webMockNetHTTP)
        Net.send(:const_set, :BufferedIO, Net::WebMockNetBufferedIO)
      end

      def self.disable!
        Net.send(:remove_const, :BufferedIO)
        Net.send(:remove_const, :HTTP)
        Net.send(:remove_const, :HTTPSession)
        Net.send(:const_set, :HTTP, OriginalNetHTTP)
        Net.send(:const_set, :HTTPSession, OriginalNetHTTP)
        Net.send(:const_set, :BufferedIO, OriginalNetBufferedIO)
      end

      @webMockNetHTTP = Class.new(Net::HTTP) do
        class << self
          def socket_type_with_webmock
            StubSocket
          end
          alias_method :socket_type_without_webmock, :socket_type
          alias_method :socket_type, :socket_type_with_webmock

          if Module.method(:const_defined?).arity == 1
            def const_defined?(name)
              super || self.superclass.const_defined?(name)
            end
          else
            def const_defined?(name, inherit=true)
              super || self.superclass.const_defined?(name, inherit)
            end
          end

          if Module.method(:const_get).arity != 1
            def const_get(name, inherit=true)
              super
            rescue NameError
              self.superclass.const_get(name, inherit)
            end
          end

          if Module.method(:constants).arity != 0
            def constants(inherit=true)
              super + self.superclass.constants(inherit)
            end
          end
        end

        def request_with_webmock(request, body = nil, &block)
          request_signature = WebMock::NetHTTPUtility.request_signature_from_request(self, request, body)

          WebMock::RequestRegistry.instance.requested_signatures.put(request_signature)

          if WebMock::StubRegistry.instance.registered_request?(request_signature)
            @socket = Net::HTTP.socket_type.new
            webmock_response = WebMock::StubRegistry.instance.response_for_request(request_signature)
            WebMock::CallbackRegistry.invoke_callbacks(
              {:lib => :net_http}, request_signature, webmock_response)
            build_net_http_response(webmock_response, &block)
          elsif WebMock.net_connect_allowed?(request_signature.uri)
            check_right_http_connection
            after_request = lambda do |response|
              if WebMock::CallbackRegistry.any_callbacks?
                webmock_response = build_webmock_response(response)
                WebMock::CallbackRegistry.invoke_callbacks(
                  {:lib => :net_http, :real_request => true}, request_signature, webmock_response)
              end
              response.extend Net::WebMockHTTPResponse
              block.call response if block
              response
            end
            response = if (started? && !WebMock::Config.instance.net_http_connect_on_start) || !started?
              @started = false #otherwise start_with_connect wouldn't execute and connect
              start_with_connect {
                response = request_without_webmock(request, nil)
                after_request.call(response)
              }
            else
              response = request_without_webmock(request, nil)
              after_request.call(response)
            end
          else
            raise WebMock::NetConnectNotAllowedError.new(request_signature)
          end
        end
        alias_method :request_without_webmock, :request
        alias_method :request, :request_with_webmock

        def start_without_connect
          raise IOError, 'HTTP session already opened' if @started
          if block_given?
            begin
              @started = true
              return yield(self)
            ensure
              do_finish
            end
          end
          @started = true
          self
        end

        def start_with_conditional_connect(&block)
          if WebMock::Config.instance.net_http_connect_on_start
            start_with_connect(&block)
          else
            start_without_connect(&block)
          end
        end
        alias_method :start_with_connect, :start
        alias_method :start, :start_with_conditional_connect

        def build_net_http_response(webmock_response, &block)
          response = Net::HTTPResponse.send(:response_class, webmock_response.status[0].to_s).new("1.0", webmock_response.status[0].to_s, webmock_response.status[1])
          response.instance_variable_set(:@body, webmock_response.body)
          webmock_response.headers.to_a.each do |name, values|
            values = [values] unless values.is_a?(Array)
            values.each do |value|
              response.add_field(name, value)
            end
          end

          response.instance_variable_set(:@read, true)

          response.extend Net::WebMockHTTPResponse

          raise Timeout::Error, "execution expired" if webmock_response.should_timeout

          webmock_response.raise_error_if_any

          yield response if block_given?

          response
        end

        def build_webmock_response(net_http_response)
          webmock_response = WebMock::Response.new
          webmock_response.status = [
             net_http_response.code.to_i,
             net_http_response.message]
          webmock_response.headers = net_http_response.to_hash
          webmock_response.body = net_http_response.body
          webmock_response
        end


        def check_right_http_connection
          unless @@alredy_checked_for_right_http_connection ||= false
            WebMock::NetHTTPUtility.puts_warning_for_right_http_if_needed
            @@alredy_checked_for_right_http_connection = true
          end
        end
      end
      @webMockNetHTTP.version_1_2
      [
        [:Get, Net::HTTP::Get],
        [:Post, Net::HTTP::Post],
        [:Put, Net::HTTP::Put],
        [:Delete, Net::HTTP::Delete],
        [:Head, Net::HTTP::Head],
        [:Options, Net::HTTP::Options]
      ].each do |c|
        @webMockNetHTTP.const_set(c[0], c[1])
      end
    end
  end
end

class StubSocket #:nodoc:

  def initialize(*args)
  end

  def closed?
    @closed ||= true
  end

  def readuntil(*args)
  end

end

module Net  #:nodoc: all

  class WebMockNetBufferedIO < BufferedIO
    def initialize_with_webmock(io, debug_output = nil)
      @read_timeout = 60
      @rbuf = ''
      @debug_output = debug_output

      @io = case io
      when Socket, OpenSSL::SSL::SSLSocket, IO
        io
      when String
        StringIO.new(io)
      end
      raise "Unable to create local socket" unless @io
    end
    alias_method :initialize_without_webmock, :initialize
    alias_method :initialize, :initialize_with_webmock
  end

end


module WebMock
  module NetHTTPUtility

    def self.request_signature_from_request(net_http, request, body = nil)
      protocol = net_http.use_ssl? ? "https" : "http"

      path = request.path
      path = WebMock::Util::URI.heuristic_parse(request.path).request_uri if request.path =~ /^http/

      if request["authorization"] =~ /^Basic /
        userinfo = WebMock::Util::Headers.decode_userinfo_from_header(request["authorization"])
        userinfo = WebMock::Util::URI.encode_unsafe_chars_in_userinfo(userinfo) + "@"
      else
        userinfo = ""
      end

      uri = "#{protocol}://#{userinfo}#{net_http.address}:#{net_http.port}#{path}"
      method = request.method.downcase.to_sym

      headers = Hash[*request.to_hash.map {|k,v| [k, v]}.inject([]) {|r,x| r + x}]

      headers.reject! {|k,v| k =~ /[Aa]uthorization/ && v.first =~ /^Basic / } #we added it to url userinfo


      if request.body_stream
        body = request.body_stream.read
        request.body_stream = nil
      end

      if body != nil && body.respond_to?(:read)
        request.set_body_internal body.read
      else
        request.set_body_internal body
      end

      WebMock::RequestSignature.new(method, uri, :body => request.body, :headers => headers)
    end


    def self.check_right_http_connection
      @was_right_http_connection_loaded = defined?(RightHttpConnection)
    end

    def self.puts_warning_for_right_http_if_needed
      if !@was_right_http_connection_loaded && defined?(RightHttpConnection)
        $stderr.puts "\nWarning: RightHttpConnection has to be required before WebMock is required !!!\n"
      end
    end

  end
end

WebMock::NetHTTPUtility.check_right_http_connection
