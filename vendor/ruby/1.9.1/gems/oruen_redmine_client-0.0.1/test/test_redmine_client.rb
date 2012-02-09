require 'helper'

class TestRedmineClient < Test::Unit::TestCase
  context "token authentication" do
    should "request should include X-Redmine-API-Key header when token is set" do
      token = "12345"
      stub_request(:get, "http://redmine.org/issues.xml")
      RedmineClient::Base.configure do
        self.site = "http://redmine.org"
        self.token = token
      end
      RedmineClient::Issue.find(:all)
      assert_requested :get, "http://redmine.org/issues.xml",
        :headers => {'X-Redmine-API-Key' => token}, :times => 1
    end
  end
end
