require 'spec_helper'

describe NotificationService::SlackService do
  it "it should send a notification to Slack with channel" do
    # setup
    notice = Fabricate :notice
    notification_service = Fabricate :slack_notification_service, :app => notice.app
    problem = notice.problem

    # faraday stubbing
    payload = {:text => notification_service.message_for_slack(problem), :channel => notification_service.room_id}.to_json
    expect(HTTParty).to receive(:post).with(notification_service.url, :body => payload, :headers => {"Content-Type" => "application/json"}).and_return(true)

    notification_service.create_notification(problem)
  end

  it "it should send a notification to Slack without a channel" do
    # setup
    notice = Fabricate :notice
    notification_service = Fabricate :slack_notification_service, :app => notice.app, :room_id => ""
    problem = notice.problem

    # faraday stubbing
    payload = {:text => notification_service.message_for_slack(problem)}.to_json
    expect(HTTParty).to receive(:post).with(notification_service.url, :body => payload, :headers => {"Content-Type" => "application/json"}).and_return(true)

    notification_service.create_notification(problem)
  end
end
