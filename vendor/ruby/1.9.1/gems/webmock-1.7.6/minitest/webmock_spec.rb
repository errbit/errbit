require File.expand_path(File.dirname(__FILE__) + '/test_helper')

  describe "Webmock" do
    include HttpRequestTestHelper

    before do
      stub_http_request(:any, "http://www.example.com")
      stub_http_request(:any, "https://www.example.com")
    end

    it "should raise error on non stubbed request" do
      lambda { http_request(:get, "http://www.example.net/") }.must_raise(WebMock::NetConnectNotAllowedError)
    end

    it "should verify that expected request occured" do
      http_request(:get, "http://www.example.com/")
      assert_requested(:get, "http://www.example.com", :times => 1)
      assert_requested(:get, "http://www.example.com")
    end

    it  "should verify that expect request didn't occur" do
     expected_message = "The request GET http://www.example.com/ was expected to execute 1 time but it executed 0 times"
     expected_message << "\n\nThe following requests were made:\n\nNo requests were made.\n============================================================"
     assert_fail(expected_message) do
       assert_requested(:get, "http://www.example.com")
     end
    end

  end

