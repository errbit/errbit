require 'spec_helper'

describe NotificationService::WebhookService do
  it "it should send a notification to a user-specified URL" do
    notice = Fabricate :notice
    notification_service = Fabricate :webhook_notification_service, :app => notice.app
    problem = notice.problem
    
    expect(HTTParty).to receive(:post).with(notification_service.api_token, :body => {:problem => problem.to_json}).and_return(true)

    notification_service.create_notification(problem)
  end
end
