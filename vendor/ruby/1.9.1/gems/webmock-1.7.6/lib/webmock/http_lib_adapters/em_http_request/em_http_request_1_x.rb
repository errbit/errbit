if defined?(EventMachine::HttpClient)
  module WebMock
    module HttpLibAdapters
      class EmHttpRequestAdapter < HttpLibAdapter
        adapter_for :em_http_request

        OriginalHttpClient = EventMachine::HttpClient unless const_defined?(:OriginalHttpClient)
        OriginalHttpConnection = EventMachine::HttpConnection unless const_defined?(:OriginalHttpConnection)


        def self.enable!
          EventMachine.send(:remove_const, :HttpConnection)
          EventMachine.send(:const_set, :HttpConnection, EventMachine::WebMockHttpConnection)
          EventMachine.send(:remove_const, :HttpClient)
          EventMachine.send(:const_set, :HttpClient, EventMachine::WebMockHttpClient)
        end

        def self.disable!
          EventMachine.send(:remove_const, :HttpConnection)
          EventMachine.send(:const_set, :HttpConnection, OriginalHttpConnection)
          EventMachine.send(:remove_const, :HttpClient)
          EventMachine.send(:const_set, :HttpClient, OriginalHttpClient)
        end
      end
    end
  end

  module EventMachine

    if defined?(Synchrony)
      # have to make the callbacks fire on the next tick in order
      # to avoid the dreaded "double resume" exception
      module HTTPMethods
        %w[get head post delete put].each do |type|
          class_eval %[
            def #{type}(options = {}, &blk)
              f = Fiber.current

               conn = setup_request(:#{type}, options, &blk)
               conn.callback { EM.next_tick { f.resume(conn) } }
               conn.errback  { EM.next_tick { f.resume(conn) } }

               Fiber.yield
            end
          ]
        end
      end
    end

    class WebMockHttpConnection < HttpConnection
      def webmock_activate_connection(client)
        request_signature = client.request_signature

        if WebMock::StubRegistry.instance.registered_request?(request_signature)
          conn = HttpStubConnection.new rand(10000)
          post_init

          @deferred = false
          @conn = conn

          conn.parent = self
          conn.pending_connect_timeout = @connopts.connect_timeout
          conn.comm_inactivity_timeout = @connopts.inactivity_timeout

          finalize_request(client)
          @conn.set_deferred_status :succeeded
        elsif WebMock.net_connect_allowed?(request_signature.uri)
          real_activate_connection(client)
        else
          raise WebMock::NetConnectNotAllowedError.new(request_signature)
        end
      end
      alias_method :real_activate_connection, :activate_connection
      alias_method :activate_connection, :webmock_activate_connection
    end

    class WebMockHttpClient < EventMachine::HttpClient
      include HttpEncoding

      def uri
        @req.uri
      end

      def setup(response, uri, error = nil)
        @last_effective_url = @uri = uri
        if error
          on_error(error)
          fail(self)
        else
          @conn.receive_data(response)
          succeed(self)
        end
      end

      def send_request_with_webmock(head, body)
        WebMock::RequestRegistry.instance.requested_signatures.put(request_signature)

        if WebMock::StubRegistry.instance.registered_request?(request_signature)
          webmock_response = WebMock::StubRegistry.instance.response_for_request(request_signature)
          on_error("WebMock timeout error") if webmock_response.should_timeout
          WebMock::CallbackRegistry.invoke_callbacks({:lib => :em_http_request}, request_signature, webmock_response)
          EM.next_tick {
            setup(make_raw_response(webmock_response), @uri,
                  webmock_response.should_timeout ? "WebMock timeout error" : nil)
          }
          self
        elsif WebMock.net_connect_allowed?(request_signature.uri)
          send_request_without_webmock(head, body)
          callback {
            if WebMock::CallbackRegistry.any_callbacks?
              webmock_response = build_webmock_response
              WebMock::CallbackRegistry.invoke_callbacks(
                {:lib => :em_http_request, :real_request => true},
                request_signature,
                webmock_response)
            end
          }
          self
        else
          raise WebMock::NetConnectNotAllowedError.new(request_signature)
        end
      end

      alias_method :send_request_without_webmock, :send_request
      alias_method :send_request, :send_request_with_webmock

      def request_signature
        @request_signature ||= build_request_signature
      end

      private

      def build_webmock_response
        webmock_response = WebMock::Response.new
        webmock_response.status = [response_header.status, response_header.http_reason]
        webmock_response.headers = response_header
        webmock_response.body = response
        webmock_response
      end

      def build_request_signature
        headers, body = @req.headers, @req.body

        @conn.middleware.select {|m| m.respond_to?(:request) }.each do |m|
          headers, body = m.request(self, headers, body)
        end

        method = @req.method
        uri = @req.uri
        auth = @req.proxy[:authorization]
        query = @req.query

        if auth
          userinfo = auth.join(':')
          userinfo = WebMock::Util::URI.encode_unsafe_chars_in_userinfo(userinfo)
          if @req
            @req.proxy.reject! {|k,v| t.to_s == 'authorization' }
          else
            options.reject! {|k,v| k.to_s == 'authorization' } #we added it to url userinfo
          end
          uri.userinfo = userinfo
        end

        uri.query = encode_query(@req.uri, query).slice(/\?(.*)/, 1)

        body = form_encode_body(body) if body.is_a?(Hash)

        WebMock::RequestSignature.new(
          method.downcase.to_sym,
          uri.to_s,
          :body => body,
          :headers => headers
        )
      end

      def make_raw_response(response)
        response.raise_error_if_any

        status, headers, body = response.status, response.headers, response.body
        headers ||= {}

        response_string = []
        response_string << "HTTP/1.1 #{status[0]} #{status[1]}"

        headers["Content-Length"] = body.length unless headers["Content-Length"]
        headers.each do |header, value|
          value = value.join(", ") if value.is_a?(Array)

          # WebMock's internal processing will not handle the body
          # correctly if the header indicates that it is chunked, unless
          # we also create all the chunks.
          # It's far easier just to remove the header.
          next if header =~ /transfer-encoding/i && value =~/chunked/i

          response_string << "#{header}: #{value}"
        end if headers

        response_string << "" << body
        response_string.join("\n")
      end
    end
  end
end
