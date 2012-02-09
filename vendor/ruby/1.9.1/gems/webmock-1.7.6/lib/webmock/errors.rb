module WebMock

  class NetConnectNotAllowedError < StandardError
    def initialize(request_signature)
      text = "Real HTTP connections are disabled. Unregistered request: #{request_signature}"
      text << "\n\n"
      text << stubbing_instructions(request_signature)
      text << request_stubs
      text << "\n\n" + "="*60
      super(text)
    end

    private

    def request_stubs
      return "" if WebMock::StubRegistry.instance.request_stubs.empty?
      text = "\n\nregistered request stubs:\n"
      WebMock::StubRegistry.instance.request_stubs.each do |stub|
        text << "\n#{WebMock::StubRequestSnippet.new(stub).to_s(false)}"
      end
      text
    end

    def stubbing_instructions(request_signature)
      text = ""
      request_stub = RequestStub.from_request_signature(request_signature)
      text << "You can stub this request with the following snippet:\n\n"
      text << WebMock::StubRequestSnippet.new(request_stub).to_s
      text
    end
  end

end
