require 'spec_helper'

describe FogbugzTracker do
  it "should create an issue on Fogbugz with problem params, and set issue link for problem" do
    notice = Fabricate :notice
    tracker = Fabricate :fogbugz_tracker, :app => notice.app
    problem = notice.problem

    number = 123
    @issue_link = "https://#{tracker.account}.fogbugz.com/default.asp?#{number}"
    response = "<response><token>12345</token><case><ixBug>123</ixBug></case></response>"
    http_mock = mock()
    http_mock.should_receive(:new).and_return(http_mock)
    http_mock.should_receive(:request).twice.and_return(response)
    Fogbugz.adapter[:http] = http_mock

    problem.app.issue_tracker.create_issue(problem)
    problem.reload

    problem.issue_link.should == @issue_link
  end
end

