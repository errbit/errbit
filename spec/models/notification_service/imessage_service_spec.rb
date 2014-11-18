require 'spec_helper'

describe NotificationService::ImessageService do
  it "it should send a notification to a iMessage user" do
    notice = Fabricate :notice
    notification_service = Fabricate :imessage_notification_service, :app => notice.app
    problem = notice.problem

    expect(Imessage::Sender).to receive(:send).with(
      message: an_instance_of(String),
      contacts: [an_instance_of(String)]
    ).and_return(true)

    notification_service.create_notification(problem)
  end
end
