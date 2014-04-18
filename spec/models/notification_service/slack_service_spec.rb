require 'spec_helper'

describe NotificationService::SlackService do
  it "it should send a notification to Slack with channel" do
    # setup
    notice = Fabricate :notice
    notification_service = Fabricate :slack_notification_service, :app => notice.app
    problem = notice.problem

    # faraday stubbing
    expect(HTTParty).to receive(:post).with(notification_service.url, :body => {:payload => {:text => an_instance_of(String), :channel => notification_service.room_id}}).and_return(true)

    notification_service.create_notification(problem)
  end

  it "it should send a notification to Slack without a channel" do
    # setup
    notice = Fabricate :notice
    notification_service = Fabricate :slack_notification_service, :app => notice.app, :room_id => ""
    problem = notice.problem

    # faraday stubbing
    expect(HTTParty).to receive(:post).with(notification_service.url, :body => {:payload => {:text => an_instance_of(String)}}).and_return(true)

    notification_service.create_notification(problem)
  end
end
