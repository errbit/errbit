require 'spec_helper'

describe NotificationService::GtalkService do
  it "it should send a notification to gtalk" do
    # setup
    notice = Fabricate :notice
    notification_service = Fabricate :gtalk_notification_service, :app => notice.app
    problem = notice.problem

    #gtalk stubbing
    gtalk = mock('GtalkService')
    jid = double("jid")
    message = double("message")
    Jabber::JID.should_receive(:new).with(notification_service.subdomain).and_return(jid)
    Jabber::Client.should_receive(:new).with(jid).and_return(gtalk)
    gtalk.should_receive(:connect)
    gtalk.should_receive(:auth).with(notification_service.api_token)
    Jabber::Message.should_receive(:new).with(notification_service.room_id, "[errbit] http://#{Errbit::Config.host}/apps/#{problem.app.id.to_s} #{notification_service.notification_description problem}").and_return(message)

    #assert
    gtalk.should_receive(:send).with(message)


    notification_service.create_notification(problem)
  end
end

