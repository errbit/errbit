require 'spec_helper'

describe NotificationServices::WebhookService do
  it "should send a notification to a user-specified URL" do
    notice = Fabricate :notice
    notification_service = Fabricate :webhook_notification_service, app: notice.app
    problem = notice.problem
    
    expect(HTTParty).to receive(:post).with(notification_service.api_token, body: {problem: problem.to_json}).and_return(true)

    notification_service.create_notification(problem)
  end

  it "should not break Errbit if the user-specified URL cannot be contacted" do
    notice = Fabricate :notice
    notification_service = Fabricate :webhook_notification_service, app: notice.app
    problem = notice.problem
    
    expect(HTTParty).to receive(:post).with(notification_service.api_token, body: {problem: problem.to_json}).and_raise(SocketError)
    
    expect {notification_service.create_notification(problem)}.to_not raise_error(SocketError)
  end
end
