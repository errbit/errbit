require 'spec_helper'

describe NotificationService::WebhookService do

  let(:service) { Fabricate(:webhook_notification_service) }
  let(:deploy) { Fabricate(:deploy) }
  let(:problem) { Fabricate(:problem) }

  it "it should send a notification to a user-specified URL for a problem" do
    expect(HTTParty).to receive(:post).
      with(service.api_token,:body => { :problem => problem.to_json }).
      and_return(true)
    service.create_notification(problem)
  end

  it "it should send a notification to a user-specified URL for a deploy" do
    expect(HTTParty).to receive(:post).
      with(service.api_token,:body => { :deploy => deploy.to_json }).
      and_return(true)
    service.create_notification(deploy)
  end

end
