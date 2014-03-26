require 'spec_helper'

describe NotificationServices::FlowdockService do
  let(:service) { Fabricate.build(:flowdock_notification_service) }
  let(:app) { Fabricate(:app, :name => 'App #3') }
  let(:problem) { Fabricate(:problem, :app => app, :message => '<3') }
  let(:deploy) {  Fabricate(:deploy) }

  it 'sends message in appropriate format' do
    Flowdock::Flow.any_instance.should_receive(:push_to_team_inbox) do |*args|
      expect(args.first[:content]).to_not include('<3')
      expect(args.first[:content]).to include('&lt;3')

      expect(args.first[:project]).to eq('App3')
    end
    service.create_notification(problem)
  end

  it 'can send a deploy message' do
    Flowdock::Flow.any_instance.
      should_receive(:push_to_team_inbox).
      with(kind_of(Hash))
    service.create_notification(deploy)
  end

end
