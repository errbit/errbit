require 'spec_helper'

describe IssueTrackers::UnfuddleTracker do

  let(:issue_link) { "https://test.unfuddle.com/projects/15/tickets/2436" }
  let(:notice) { Fabricate :notice }
  let(:tracker) { Fabricate :unfuddle_issues_tracker, :app => notice.app }
  let(:problem) { notice.problem }

  it "should create an issue on Unfuddle Issues with problem params, and set issue link for problem" do
project_xml = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <account-id type="integer">1</account-id>
  <archived type="boolean">false</archived>
  <assignee-on-resolve>reporter</assignee-on-resolve>
  <backup-frequency type="integer">0</backup-frequency>
  <close-ticket-simultaneously-default type="boolean">false</close-ticket-simultaneously-default>
  <default-ticket-report-id type="integer" nil="true"></default-ticket-report-id>
  <description nil="true"></description>
  <disk-usage type="integer">27932</disk-usage>
  <enable-time-tracking type="boolean">true</enable-time-tracking>
  <id type="integer">#{tracker.project_id}</id>
  <s3-access-key-id></s3-access-key-id>
  <s3-backup-enabled type="boolean">false</s3-backup-enabled>
  <s3-bucket-name></s3-bucket-name>
  <short-name>test-project</short-name>
  <theme>blue</theme>
  <ticket-field1-active type="boolean">false</ticket-field1-active>
  <ticket-field1-disposition>text</ticket-field1-disposition>
  <ticket-field1-title>Field 1</ticket-field1-title>
  <ticket-field2-active type="boolean">false</ticket-field2-active>
  <ticket-field2-disposition>text</ticket-field2-disposition>
  <ticket-field2-title>Field 2</ticket-field2-title>
  <ticket-field3-active type="boolean">false</ticket-field3-active>
  <ticket-field3-disposition>text</ticket-field3-disposition>
  <ticket-field3-title>Field 3</ticket-field3-title>
  <title>test-project</title>
  <created-at>2011-04-25T09:21:43Z</created-at>
  <updated-at>2013-03-08T08:03:02Z</updated-at>
</project>
EOF

    ticket_xml =<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<ticket>
  <assignee-id type="integer">40</assignee-id>
  <component-id type="integer" nil="true"></component-id>
  <description nil="true"></description>
  <description-format>markdown</description-format>
  <due-on type="date" nil="true"></due-on>
  <field1-value-id type="integer" nil="true"></field1-value-id>
  <field2-value-id type="integer" nil="true"></field2-value-id>
  <field3-value-id type="integer" nil="true"></field3-value-id>
  <hours-estimate-current type="float">1268.7</hours-estimate-current>
  <hours-estimate-initial type="float">0.0</hours-estimate-initial>
  <id type="integer">2436</id>
  <milestone-id type="integer">78</milestone-id>
  <number type="integer">119</number>
  <priority>3</priority>
  <project-id type="integer">15</project-id>
  <reporter-id type="integer">40</reporter-id>
  <resolution></resolution>
  <resolution-description></resolution-description>
  <resolution-description-format>markdown</resolution-description-format>
  <severity-id type="integer" nil="true"></severity-id>
  <status>reopened</status>
  <summary>TEST-ticket.</summary>
  <version-id type="integer" nil="true"></version-id>
  <created-at>2012-06-27T17:49:06Z</created-at>
  <updated-at>2013-03-07T16:04:05Z</updated-at>
</ticket>
EOF

    stub_request(:get, "https://#{tracker.username}:#{tracker.password}@test.unfuddle.com/api/v1/projects/#{tracker.project_id}.xml").
      to_return(:status => 200, :body => project_xml, :headers => {})


    stub_request(:post, "https://#{tracker.username}:#{tracker.password}@test.unfuddle.com/api/v1/projects/#{tracker.project_id}/tickets.xml").
      to_return(:status => 200, :body => ticket_xml, :headers => {})

    problem.app.issue_tracker.create_issue(problem)
    problem.reload

    requested = have_requested(:post,"https://#{tracker.username}:#{tracker.password}@test.unfuddle.com/api/v1/projects/#{tracker.project_id}/tickets.xml" )
    expect(WebMock).to requested.with(:title => /[production][foo#bar] FooError: Too Much Bar/)
    expect(WebMock).to requested.with(:content => /See this exception on Errbit/)

    expect(problem.issue_link).to eq issue_link
    expect(problem.issue_type).to eq IssueTrackers::UnfuddleTracker::Label
  end
end
