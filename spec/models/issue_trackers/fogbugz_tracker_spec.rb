require 'spec_helper'

describe IssueTrackers::FogbugzTracker do
  it "should create an issue on Fogbugz with problem params, and set issue link for problem" do
    notice = Fabricate :notice
    tracker = Fabricate :fogbugz_tracker, :app => notice.app
    problem = notice.problem

    number = 123
    @issue_link = "https://#{tracker.account}.fogbugz.com/default.asp?#{number}"
    response = "<response><token>12345</token><case><ixBug>123</ixBug></case></response>"
    http_mock = double
    expect(http_mock).to receive(:new).and_return(http_mock)
    expect(http_mock).to receive(:request).twice.and_return(response)
    Fogbugz.adapter[:http] = http_mock

    problem.app.issue_tracker.create_issue(problem)
    problem.reload

    expect(problem.issue_link).to eq @issue_link
  end
end

