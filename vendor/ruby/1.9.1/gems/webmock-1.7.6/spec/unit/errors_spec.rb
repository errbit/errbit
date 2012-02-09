require 'spec_helper'

describe "errors" do
  describe WebMock::NetConnectNotAllowedError do
    describe "message" do
      it "should have message with request signature and snippet" do
        request_signature = mock(:to_s => "aaa")
        request_stub = mock
        WebMock::RequestStub.stub!(:from_request_signature).and_return(request_stub)
        WebMock::StubRequestSnippet.stub!(:new).
          with(request_stub).and_return(mock(:to_s => "bbb"))
        expected =  "Real HTTP connections are disabled. Unregistered request: aaa" +
               "\n\nYou can stub this request with the following snippet:\n\n" +
               "bbb\n\n============================================================"
        WebMock::NetConnectNotAllowedError.new(request_signature).message.should == expected
      end

      it "should have message with registered stubs if available" do
        request_signature = mock(:to_s => "aaa")
        request_stub = mock
        WebMock::StubRegistry.instance.stub!(:request_stubs).and_return([request_stub])
        WebMock::RequestStub.stub!(:from_request_signature).and_return(request_stub)
        WebMock::StubRequestSnippet.stub!(:new).
          with(request_stub).and_return(mock(:to_s => "bbb"))
        expected =  "Real HTTP connections are disabled. Unregistered request: aaa" +
               "\n\nYou can stub this request with the following snippet:\n\n" +
               "bbb\n\nregistered request stubs:\n\nbbb\n\n============================================================"
        WebMock::NetConnectNotAllowedError.new(request_signature).message.should == expected
      end
    end
  end
end
