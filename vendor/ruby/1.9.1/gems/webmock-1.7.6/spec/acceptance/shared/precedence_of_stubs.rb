shared_context "precedence of stubs" do
  describe "when choosing a matching request stub" do
    it "should use the last declared matching request stub" do
      stub_request(:get, "www.example.com").to_return(:body => "abc")
      stub_request(:get, "www.example.com").to_return(:body => "def")
      http_request(:get, "http://www.example.com/").body.should == "def"
    end

    it "should not be affected by the type of uri or request method" do
      stub_request(:get, "www.example.com").to_return(:body => "abc")
      stub_request(:any, /.*example.*/).to_return(:body => "def")
      http_request(:get, "http://www.example.com/").body.should == "def"
    end
  end
end
