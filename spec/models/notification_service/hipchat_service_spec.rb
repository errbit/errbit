require 'spec_helper'

describe NotificationServices::HipchatService do
  let(:service) { Fabricate.build(:hipchat_notification_service) }
  let(:problem) { Fabricate(:problem) }
  let(:room) { double }

  before do
    HipChat::Client.any_instance.stub(:[] => room)
  end

  it 'sends message' do
    room.should_receive(:send)
    service.create_notification(problem)
  end

  it 'escapes html in message' do
    problem.stub(:message => '<3')
    room.should_receive(:send) do |_, message|
      message.should_not include('<3')
      message.should include('&lt;3')
    end
    service.create_notification(problem)
  end
end
