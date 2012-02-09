shared_context "allowing and disabling net connect" do
  describe "when net connect" do
    describe "is allowed", :net_connect => true do
      before(:each) do
        WebMock.allow_net_connect!
      end

      it "should make a real web request if request is not stubbed" do
        http_request(:get, webmock_server_url).status.should == "200"
      end

      it "should make a real https request if request is not stubbed" do
        unless http_library == :httpclient
          http_request(:get, "https://www.paypal.com/uk/cgi-bin/webscr").
            body.should =~ /.*paypal.*/
        end
      end

      it "should return stubbed response if request was stubbed" do
        stub_request(:get, "www.example.com").to_return(:body => "abc")
        http_request(:get, "http://www.example.com/").body.should == "abc"
      end
    end

    describe "is not allowed" do
      before(:each) do
        WebMock.disable_net_connect!
      end

      it "should return stubbed response if request was stubbed" do
        stub_request(:get, "www.example.com").to_return(:body => "abc")
        http_request(:get, "http://www.example.com/").body.should == "abc"
      end

      it "should return stubbed response if request with path was stubbed" do
        stub_request(:get, "www.example.com/hello_world").to_return(:body => "abc")
        http_request(:get, "http://www.example.com/hello_world").body.should == "abc"
      end

      it "should raise exception if request was not stubbed" do
        lambda {
          http_request(:get, "http://www.example.com/")
        }.should raise_error(WebMock::NetConnectNotAllowedError, %r(Real HTTP connections are disabled. Unregistered request: GET http://www.example.com/))
      end
    end

    describe "is not allowed with exception for localhost" do
      before(:each) do
        WebMock.disable_net_connect!(:allow_localhost => true)
      end

      it "should return stubbed response if request was stubbed" do
        stub_request(:get, "www.example.com").to_return(:body => "abc")
        http_request(:get, "http://www.example.com/").body.should == "abc"
      end

      it "should raise exception if request was not stubbed" do
        lambda {
          http_request(:get, "http://www.example.com/")
        }.should raise_error(WebMock::NetConnectNotAllowedError, %r(Real HTTP connections are disabled. Unregistered request: GET http://www.example.com/))
      end

      it "should make a real request to localhost" do
        lambda {
          http_request(:get, "http://localhost:12345/")
        }.should raise_error(connection_refused_exception_class)
      end

      it "should make a real request to 127.0.0.1" do
        lambda {
          http_request(:get, "http://127.0.0.1:12345/")
        }.should raise_error(connection_refused_exception_class)
      end

      it "should make a real request to 0.0.0.0" do
        lambda {
          http_request(:get, "http://0.0.0.0:12345/")
        }.should raise_error(connection_refused_exception_class)
      end
    end

    describe "is not allowed with exception for allowed domains" do
      let(:host_with_port){ WebMockServer.instance.host_with_port }

      before(:each) do
        WebMock.disable_net_connect!(:allow => ["www.example.org", host_with_port])
      end

      context "when the host is not allowed" do
        it "should return stubbed response if request was stubbed" do
          stub_request(:get, "www.example.com").to_return(:body => "abc")
          http_request(:get, "http://www.example.com/").body.should == "abc"
        end

        it "should raise exception if request was not stubbed" do
          lambda {
            http_request(:get, "http://www.example.com/")
          }.should raise_error(WebMock::NetConnectNotAllowedError, %r(Real HTTP connections are disabled. Unregistered request: GET http://www.example.com/))
        end
      end

      context "when the host with port is not allowed" do
        it "should return stubbed response if request was stubbed" do
          stub_request(:get, "http://localhost:2345").to_return(:body => "abc")
          http_request(:get, "http://localhost:2345/").body.should == "abc"
        end

        it "should raise exception if request was not stubbed" do
          lambda {
            http_request(:get, "http://localhost:2345/")
          }.should raise_error(WebMock::NetConnectNotAllowedError, %r(Real HTTP connections are disabled. Unregistered request: GET http://localhost:2345/))
        end
      end

      context "when the host is allowed" do
        it "should raise exception if request was not stubbed" do
          lambda {
            http_request(:get, "http://www.example.com/")
          }.should raise_error(WebMock::NetConnectNotAllowedError, %r(Real HTTP connections are disabled. Unregistered request: GET http://www.example.com/))
        end

        it "should make a real request to allowed host", :net_connect => true do
          http_request(:get, "http://www.example.org/").status.should == "302"
        end
      end

      context "when the host with port is allowed" do
        it "should make a real request to allowed host", :net_connect => true do
          http_request(:get, "http://#{host_with_port}/").status.should == "200"
        end
      end

      context "when the host is allowed but not port" do
        it "should make a real request to allowed host", :net_connect => true do
          lambda {
            http_request(:get, "http://localhost:123/")
          }.should raise_error(WebMock::NetConnectNotAllowedError, %r(Real HTTP connections are disabled. Unregistered request: GET http://localhost:123/))
        end
      end
    end
  end
end
