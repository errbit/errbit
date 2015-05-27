describe NotificationServices::HipchatService, type: 'model' do
  let(:service) { Fabricate.build(:hipchat_notification_service) }
  let(:problem) { Fabricate(:problem) }
  let(:room) { double }

  before do
    allow_any_instance_of(HipChat::Client).to receive(:[]).and_return(room)
  end

  describe '#check_params' do
    context 'empty field check' do
      %w(service api_token room_id).each do |field|
        it "'doesn\'t allow #{field} to be empty'" do
          service[field.to_sym] = ''
          service.check_params
          expect(service.errors).to include(field.to_sym)
        end
      end
    end

    context 'API version field check' do
      %w(v1 v2).each do |version|
        it "allows #{version}" do
          service[:service] = version
          service.check_params
          expect(service.errors).to_not include(:service)
        end
      end

      it 'doesn\t allow an unknown version' do
        service[:service] = 'vFOO'
        service.check_params
        expect(service.errors).to include(:service)
      end
    end
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
