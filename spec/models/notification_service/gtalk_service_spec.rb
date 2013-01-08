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

  describe "multiple room_ids (or users)" do
    before(:each) do
      # setup
      @notice = Fabricate :notice
      @notification_service = Fabricate :gtalk_notification_service, :app => @notice.app
      @problem = @notice.problem
      @error_msg = "[errbit] http://#{Errbit::Config.host}/apps/#{@problem.app.id.to_s} #{@notification_service.notification_description @problem}"

      # gtalk stubbing
      @gtalk = mock('GtalkService')
      @gtalk.should_receive(:connect)
      @gtalk.should_receive(:auth)
      jid = double("jid")
      Jabber::JID.stub(:new).with(@notification_service.subdomain).and_return(jid)
      Jabber::Client.stub(:new).with(jid).and_return(@gtalk)
    end
    it "should send a notification to all ',' separated users" do
      Jabber::Message.should_receive(:new).with("first@domain.org", @error_msg)
      Jabber::Message.should_receive(:new).with("second@domain.org", @error_msg)
      Jabber::Message.should_receive(:new).with("third@domain.org", @error_msg)
      Jabber::Message.should_receive(:new).with("fourth@domain.org", @error_msg)
      @gtalk.should_receive(:send).exactly(4).times

      @notification_service.room_id = "first@domain.org,second@domain.org, third@domain.org ,   fourth@domain.org  "
      @notification_service.create_notification(@problem)
    end
    it "should send a notification to all ';' separated users" do
      Jabber::Message.should_receive(:new).with("first@domain.org", @error_msg)
      Jabber::Message.should_receive(:new).with("second@domain.org", @error_msg)
      Jabber::Message.should_receive(:new).with("third@domain.org", @error_msg)
      Jabber::Message.should_receive(:new).with("fourth@domain.org", @error_msg)
      @gtalk.should_receive(:send).exactly(4).times

      @notification_service.room_id = "first@domain.org;second@domain.org; third@domain.org ;   fourth@domain.org  "
      @notification_service.create_notification(@problem)
    end
    it "should send a notification to all ' ' separated users" do
      Jabber::Message.should_receive(:new).with("first@domain.org", @error_msg)
      Jabber::Message.should_receive(:new).with("second@domain.org", @error_msg)
      Jabber::Message.should_receive(:new).with("third@domain.org", @error_msg)
      Jabber::Message.should_receive(:new).with("fourth@domain.org", @error_msg)
      @gtalk.should_receive(:send).exactly(4).times

      @notification_service.room_id = "first@domain.org second@domain.org  third@domain.org     fourth@domain.org  "
      @notification_service.create_notification(@problem)
    end
  end
end

