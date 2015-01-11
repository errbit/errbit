describe NotificationServices::HipchatService, type: 'model' do
  let(:service) { Fabricate.build(:hipchat_notification_service) }
  let(:problem) { Fabricate(:problem) }
  let(:room) { double }

  before do
    allow_any_instance_of(HipChat::Client).to receive(:[]).and_return(room)
  end

  it 'sends message' do
    expect(room).to receive(:send)
    service.create_notification(problem)
  end

  it 'escapes html in message' do
    allow(problem).to receive(:message).and_return('<3')
    expect(room).to receive(:send) do |_, message|
      expect(message).to_not include('<3')
      expect(message).to include('&lt;3')
    end
    service.create_notification(problem)
  end
end
