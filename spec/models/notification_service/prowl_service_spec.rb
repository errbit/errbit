require 'spec_helper'

describe NotificationServices::ProwlService do
  let(:service) { Fabricate.build(:prowl_notification_service) }
  let(:app) { Fabricate(:app, :name => 'App #3') }
  let(:problem) { Fabricate(:problem, :app => app, :message => 'NullPointerException') }

  it 'sends message in appropriate format' do
    Prowl.should_receive(:add) do |*args|
      expect(args.first[:description]).to include('NullPointerException')
      expect(args.first[:application]).to include('App #3')
    end
    service.create_notification(problem)
  end
end
