module WebMock
  class StubRequestSnippet
    def initialize(request_stub)
      @request_stub = request_stub
    end

    def to_s(with_response = true)
      request_pattern = @request_stub.request_pattern
      string = "stub_request(:#{request_pattern.method_pattern.to_s},"
      string << " \"#{request_pattern.uri_pattern.to_s}\")"

      with = ""

      if (request_pattern.body_pattern)
        with << ":body => #{request_pattern.body_pattern.to_s}"
      end

      if (request_pattern.headers_pattern)
        with << ",\n       " unless with.empty?

        with << ":headers => #{request_pattern.headers_pattern.to_s}"
      end
      string << ".\n  with(#{with})" unless with.empty?
      if with_response
        string << ".\n  to_return(:status => 200, :body => \"\", :headers => {})"
      end
      string
    end
  end
end
