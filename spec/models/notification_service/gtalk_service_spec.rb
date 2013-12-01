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
    expect(Jabber::JID).to receive(:new).with(notification_service.subdomain).and_return(jid)
    expect(Jabber::Client).to receive(:new).with(jid).and_return(gtalk)
    expect(gtalk).to receive(:connect).with(notification_service.service)
    expect(gtalk).to receive(:auth).with(notification_service.api_token)
    message_value = """#{problem.app.name.to_s}
http://#{Errbit::Config.host}/apps/#{problem.app.id.to_s}
#{notification_service.notification_description problem}"""

    expect(Jabber::Message).to receive(:new).with(notification_service.user_id, message_value).and_return(message)
    expect(Jabber::Message).to receive(:new).with(notification_service.room_id, message_value).and_return(message)

    expect(Jabber::MUC::SimpleMUCClient).to receive(:new).and_return(gtalk)
    expect(gtalk).to receive(:join).with(notification_service.room_id + "/errbit")

    #assert
    expect(gtalk).to receive(:send).exactly(2).times.with(message)

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
      expect(@gtalk).to receive(:connect)
      expect(@gtalk).to receive(:auth)
      jid = double("jid")
      Jabber::JID.stub(:new).with(@notification_service.subdomain).and_return(jid)
      Jabber::Client.stub(:new).with(jid).and_return(@gtalk)
    end
    it "should send a notification to all ',' separated users" do
      expect(Jabber::Message).to receive(:new).with("first@domain.org", @error_msg)
      expect(Jabber::Message).to receive(:new).with("second@domain.org", @error_msg)
      expect(Jabber::Message).to receive(:new).with("third@domain.org", @error_msg)
      expect(Jabber::Message).to receive(:new).with("fourth@domain.org", @error_msg)
      expect(Jabber::MUC::SimpleMUCClient).to_not receive(:new)
      expect(@gtalk).to receive(:send).exactly(4).times

      @notification_service.user_id = "first@domain.org,second@domain.org, third@domain.org ,   fourth@domain.org  "
      @notification_service.room_id = ""
      @notification_service.create_notification(@problem)
    end
    it "should send a notification to all ';' separated users" do
      expect(Jabber::Message).to receive(:new).with("first@domain.org", @error_msg)
      expect(Jabber::Message).to receive(:new).with("second@domain.org", @error_msg)
      expect(Jabber::Message).to receive(:new).with("third@domain.org", @error_msg)
      expect(Jabber::Message).to receive(:new).with("fourth@domain.org", @error_msg)
      expect(Jabber::MUC::SimpleMUCClient).to_not receive(:new)
      expect(@gtalk).to receive(:send).exactly(4).times

      @notification_service.user_id = "first@domain.org;second@domain.org; third@domain.org ;   fourth@domain.org  "
      @notification_service.room_id = ""
      @notification_service.create_notification(@problem)
    end
    it "should send a notification to all ' ' separated users" do
      expect(Jabber::Message).to receive(:new).with("first@domain.org", @error_msg)
      expect(Jabber::Message).to receive(:new).with("second@domain.org", @error_msg)
      expect(Jabber::Message).to receive(:new).with("third@domain.org", @error_msg)
      expect(Jabber::Message).to receive(:new).with("fourth@domain.org", @error_msg)
      expect(Jabber::MUC::SimpleMUCClient).to_not receive(:new)
      expect(@gtalk).to receive(:send).exactly(4).times

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
    expect(Jabber::JID).to receive(:new).with(notification_service.subdomain).and_return(jid)
    expect(Jabber::Client).to receive(:new).with(jid).and_return(gtalk)
    expect(gtalk).to receive(:connect)
    expect(gtalk).to receive(:auth).with(notification_service.api_token)
    message_value = """#{problem.app.name.to_s}
http://#{Errbit::Config.host}/apps/#{problem.app.id.to_s}
#{notification_service.notification_description problem}"""

    expect(Jabber::Message).to receive(:new).with(notification_service.room_id, message_value).and_return(message)

    expect(Jabber::MUC::SimpleMUCClient).to receive(:new).and_return(gtalk)
    expect(gtalk).to receive(:join).with(notification_service.room_id + "/errbit")

    notification_service.user_id = ""

    #assert
    expect(gtalk).to receive(:send).with(message)

    notification_service.create_notification(problem)
  end

end

