describe NotificationServices::FlowdockService, type: 'model' do
  let(:service) { Fabricate.build(:flowdock_notification_service) }
  let(:app) { Fabricate(:app, name: 'App #3') }
  let(:problem) { Fabricate(:problem, app: app, message: '<3') }

  it 'sends message in appropriate format' do
    allow_any_instance_of(Flowdock::Flow).to receive(:push_to_team_inbox) do |*args|
      expect(args[1][:content]).to_not include('<3')
      expect(args[1][:content]).to include('&lt;3')
      expect(args[1][:project]).to eq('App3')
    end

    service.create_notification(problem)
  end
end
