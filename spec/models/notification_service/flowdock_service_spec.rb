require 'spec_helper'

describe NotificationServices::FlowdockService do
  let(:service) { Fabricate.build(:flowdock_notification_service) }
  let(:app) { Fabricate(:app, :name => 'App #3') }
  let(:problem) { Fabricate(:problem, :app => app, :message => '<3') }

  it 'sends message in appropriate format' do
    Flowdock::Flow.any_instance.should_receive(:push_to_team_inbox) do |*args|
      args.first[:content].should_not include('<3')
      args.first[:content].should include('&lt;3')

      args.first[:project].should eq('App3')
    end
    service.create_notification(problem)
  end
end
