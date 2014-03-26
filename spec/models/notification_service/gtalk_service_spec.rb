require 'spec_helper'

describe NotificationService::GtalkService do
  let(:problem) { Fabricate(:problem_with_errs) }
  let(:deploy) { Fabricate(:deploy) }

  before(:each) do
    Jabber::Client.any_instance.stub(connect: nil, auth: nil, send: nil)
  end

  it "it should send a notification to gtalk users for a problem" do
    service = Fabricate(:gtalk_notification_service, room_id: nil)
    service.should_receive(:send_to_users).
      with(kind_of(Jabber::Client), kind_of(String))
    service.create_notification(problem)
  end

  it "it should send a notification to gtalk rooms for a problem" do
    # setup
    service = Fabricate(:gtalk_notification_service, user_id: nil)
    service.should_receive(:send_to_muc).
      with(kind_of(Jabber::Client), kind_of(String))
    service.create_notification(problem)
  end

  it "can handle a range of delimiters in the user id" do
    service = Fabricate(:gtalk_notification_service, room_id: nil)
    users =  %w(first@domain.org second@domain.org third@domain.org fourth@domain.org)
    users.each do |user|
      Jabber::Message.should_receive(:new).with(user, kind_of(String))
    end
    Jabber::Client.any_instance.should_receive(:send).exactly(4).times

    service.user_id = [',', ' ', ';', ' ;,'].each_with_index.map do |delim, i|
      users[i] + delim
    end.join('')
    service.create_notification(problem)
  end

  it 'can handle a notification from a deploy' do
    service = Fabricate(:gtalk_notification_service)
    service.should_receive(:send_to_users).
      with(kind_of(Jabber::Client), kind_of(String))
    service.should_receive(:send_to_muc).
      with(kind_of(Jabber::Client), kind_of(String))
    service.create_notification(deploy)
  end
end

