shared_context "enabled and disabled webmock" do
  describe "when webmock is disabled" do
    before(:each) do
      WebMock.disable!
    end
    after(:each) do
      WebMock.enable!
    end
    include_context "disabled WebMock"
  end

  describe "when webmock is enabled again" do
    before(:each) do
      WebMock.disable!
      WebMock.enable!
    end
    include_context "enabled WebMock"
  end

  describe "when webmock is disabled except this lib" do
    before(:each) do
      WebMock.disable!(:except => [http_library])
    end
    after(:each) do
      WebMock.enable!
    end
    include_context "enabled WebMock"
  end

  describe "when webmock is enabled except this lib" do
    before(:each) do
      WebMock.disable!
      WebMock.enable!(:except => [http_library])
    end
    after(:each) do
      WebMock.enable!
    end
    include_context "disabled WebMock"
  end
end

shared_context "disabled WebMock" do
  it "should not register executed requests" do
    http_request(:get, "http://www.example.com/")
    a_request(:get, "http://www.example.com/").should_not have_been_made
  end

  it "should not block unstubbed requests" do
    lambda {
      http_request(:get, "http://www.example.com/")
    }.should_not raise_error
  end

  it "should return real response even if there are stubs" do
    stub_request(:get, /.*/).to_return(:body => "x")
    http_request(:get, "http://www.example.com/").
      status.should == "302"
  end

  it "should not invoke any callbacks" do
    WebMock.reset_callbacks
    stub_request(:get, "http://www.example.com/")
    @called = nil
    WebMock.after_request { @called = 1 }
    http_request(:get, "http://www.example.com/")
    @called.should == nil
  end
end

shared_context "enabled WebMock" do
  it "should register executed requests" do
    WebMock.allow_net_connect!
    http_request(:get, "http://www.example.com/")
    a_request(:get, "http://www.example.com/").should have_been_made
  end

  it "should block unstubbed requests" do
    lambda {
      http_request(:get, "http://www.example.com/")
    }.should raise_error(WebMock::NetConnectNotAllowedError)
  end

  it "should return stubbed response" do
    stub_request(:get, /.*/).to_return(:body => "x")
    http_request(:get, "http://www.example.com/").body.should == "x"
  end

  it "should invoke callbacks" do
    WebMock.allow_net_connect!
    WebMock.reset_callbacks
    @called = nil
    WebMock.after_request { @called = 1 }
    http_request(:get, "http://www.example.com/")
    @called.should == 1
  end
end
