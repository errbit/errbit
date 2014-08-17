require 'spec_helper'

describe NotificationService::HubotService do
  let(:service) { Fabricate(:hubot_notification_service) }
  let(:problem) { Fabricate(:problem_with_errs) }
  let(:deploy) { Fabricate(:deploy) }

  it "it should send a notification to Hubot for a deploy" do
    expect(HTTParty).to receive(:post).
      with(service.api_token,
           :body => {
             :message =>
             an_instance_of(String),
             :room => service.room_id }).
      and_return(true)

    service.create_notification(problem)
  end

  it "it should send a notification to Hubot for a deploy" do
    expect(HTTParty).to receive(:post).
      with(service.api_token,
           :body => {
             :message =>
             an_instance_of(String),
             :room => service.room_id
           }).
      and_return(true)

    service.create_notification(deploy)
  end

end
