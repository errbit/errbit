require 'spec_helper'

describe NotificationService::GtalkService do
  it "it should send a notification to gtalk" do
    # setup
    notice = Fabricate :notice
    problem = notice.problem
    notification_service = Fabricate :gtalk_notification_service, :app => notice.app
    problem = notice.problem

    #gtalk stubbing
    gtalk = double('GtalkService')
    jid = double("jid")
    message = double("message")
    Jabber::JID.should_receive(:new).with(notification_service.subdomain).and_return(jid)
    Jabber::Client.should_receive(:new).with(jid).and_return(gtalk)
    gtalk.should_receive(:connect).with(notification_service.service)
    gtalk.should_receive(:auth).with(notification_service.api_token)
    message_value = """#{problem.app.name.to_s}
http://#{Errbit::Config.host}/apps/#{problem.app.id.to_s}
#{notification_service.notification_description problem}"""

    Jabber::Message.should_receive(:new).with(notification_service.user_id, message_value).and_return(message)
    Jabber::Message.should_receive(:new).with(notification_service.room_id, message_value).and_return(message)

    Jabber::MUC::SimpleMUCClient.should_receive(:new).and_return(gtalk)
    gtalk.should_receive(:join).with(notification_service.room_id + "/errbit")

    #assert
    gtalk.should_receive(:send).exactly(2).times.with(message)

    notification_service.create_notification(problem)
  end

  describe "multiple users_ids" do
    before(:each) do
      # setup
      @notice = Fabricate :notice
      @notification_service = Fabricate :gtalk_notification_service, :app => @notice.app
      @problem = @notice.problem
      @error_msg = """#{@problem.app.name.to_s}
http://#{Errbit::Config.host}/apps/#{@problem.app.id.to_s}
#{@notification_service.notification_description @problem}"""

      # gtalk stubbing
      @gtalk = double('GtalkService')
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
      Jabber::MUC::SimpleMUCClient.should_not_receive(:new)
      @gtalk.should_receive(:send).exactly(4).times

      @notification_service.user_id = "first@domain.org,second@domain.org, third@domain.org ,   fourth@domain.org  "
      @notification_service.room_id = ""
      @notification_service.create_notification(@problem)
    end
    it "should send a notification to all ';' separated users" do
      Jabber::Message.should_receive(:new).with("first@domain.org", @error_msg)
      Jabber::Message.should_receive(:new).with("second@domain.org", @error_msg)
      Jabber::Message.should_receive(:new).with("third@domain.org", @error_msg)
      Jabber::Message.should_receive(:new).with("fourth@domain.org", @error_msg)
      Jabber::MUC::SimpleMUCClient.should_not_receive(:new)
      @gtalk.should_receive(:send).exactly(4).times

      @notification_service.user_id = "first@domain.org;second@domain.org; third@domain.org ;   fourth@domain.org  "
      @notification_service.room_id = ""
      @notification_service.create_notification(@problem)
    end
    it "should send a notification to all ' ' separated users" do
      Jabber::Message.should_receive(:new).with("first@domain.org", @error_msg)
      Jabber::Message.should_receive(:new).with("second@domain.org", @error_msg)
      Jabber::Message.should_receive(:new).with("third@domain.org", @error_msg)
      Jabber::Message.should_receive(:new).with("fourth@domain.org", @error_msg)
      Jabber::MUC::SimpleMUCClient.should_not_receive(:new)
      @gtalk.should_receive(:send).exactly(4).times

      @notification_service.user_id = "first@domain.org second@domain.org  third@domain.org     fourth@domain.org  "
      @notification_service.room_id = ""
      @notification_service.create_notification(@problem)
    end

  end

  it "it should send a notification to room only" do
    # setup
    notice = Fabricate :notice
    problem = notice.problem
    notification_service = Fabricate :gtalk_notification_service, :app => notice.app
    problem = notice.problem

    #gtalk stubbing
    gtalk = double('GtalkService')
    jid = double("jid")
    message = double("message")
    Jabber::JID.should_receive(:new).with(notification_service.subdomain).and_return(jid)
    Jabber::Client.should_receive(:new).with(jid).and_return(gtalk)
    gtalk.should_receive(:connect)
    gtalk.should_receive(:auth).with(notification_service.api_token)
    message_value = """#{problem.app.name.to_s}
http://#{Errbit::Config.host}/apps/#{problem.app.id.to_s}
#{notification_service.notification_description problem}"""

    Jabber::Message.should_receive(:new).with(notification_service.room_id, message_value).and_return(message)

    Jabber::MUC::SimpleMUCClient.should_receive(:new).and_return(gtalk)
    gtalk.should_receive(:join).with(notification_service.room_id + "/errbit")

    notification_service.user_id = ""

    #assert
    gtalk.should_receive(:send).with(message)

    notification_service.create_notification(problem)
  end

end

