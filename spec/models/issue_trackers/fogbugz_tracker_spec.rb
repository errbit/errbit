# encoding: utf-8
require 'spec_helper'

describe FogbugzTracker do
  let(:notice) { Factory :notice }
  let(:tracker) { Factory :fogbugz_tracker, :password => "password", :app => notice.err.app }
  let(:err) { notice.err }

  before do
    number = 123
    @issue_link = "https://#{tracker.account}.fogbugz.com/default.asp?#{number}"
    auth_response = "<response><token>12345</token></response>"
    command_response = "<response><case><ixBug>123</ixBug></case></response>"
    http_mock = mock()
    http_mock.should_receive(:new).and_return(http_mock)
    http_mock.should_receive(:request).with(:logon, {:params=>{:email=>"test@example.com", :password=>"password"}}).
              and_return(auth_response)
    http_mock.should_receive(:request).
              and_return(command_response)
    Fogbugz.adapter[:http] = http_mock
  end

  it "should create an issue on Fogbugz with err params, and set issue link for err" do
    err.app.issue_tracker.create_issue(err)
    err.reload

    err.issue_link.should == @issue_link
  end
end

