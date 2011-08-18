require 'spec_helper'

describe FogbugzTracker do
  it "should create an issue on Fogbugz with err params, and set issue link for err" do
    notice = Factory :notice
    tracker = Factory :fogbugz_tracker, :app => notice.err.app
    err = notice.err

    number = 123
    @issue_link = "https://#{tracker.account}.fogbugz.com/default.asp?#{number}"
    response = "<response><token>12345</token><case><ixBug>123</ixBug></case></response>"
    http_mock = mock()
    http_mock.should_receive(:new).and_return(http_mock)
    http_mock.should_receive(:request).twice.and_return(response)
    Fogbugz.adapter[:http] = http_mock

    err.app.issue_tracker.create_issue(err)
    err.reload

    err.issue_link.should == @issue_link
  end
end

