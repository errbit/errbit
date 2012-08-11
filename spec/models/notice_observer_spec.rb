require 'spec_helper'

describe NoticeObserver do
  describe "email notifications (configured individually for each app)" do
    custom_thresholds = [2, 4, 8, 16, 32, 64]

    before do
      Errbit::Config.per_app_email_at_notices = true
      @app = Fabricate(:app_with_watcher, :email_at_notices => custom_thresholds)
      @err = Fabricate(:err, :problem => Fabricate(:problem, :app => @app))
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    custom_thresholds.each do |threshold|
      it "sends an email notification after #{threshold} notice(s)" do
        @err.problem.stub(:notices_count).and_return(threshold)
        Mailer.should_receive(:err_notification).
          and_return(mock('email', :deliver => true))
        Fabricate(:notice, :err => @err)
      end
    end
  end

  describe "email notifications for a resolved issue" do
    before do
      Errbit::Config.per_app_email_at_notices = true
      @app = Fabricate(:app_with_watcher, :email_at_notices => [1])
      @err = Fabricate(:err, :problem => Fabricate(:problem, :app => @app, :notices_count => 100))
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    it "should send email notification after 1 notice since an error has been resolved" do
      @err.problem.resolve!
      Mailer.should_receive(:err_notification).
        and_return(mock('email', :deliver => true))
      Fabricate(:notice, :err => @err)
    end
  end

  describe "should send a notification if a notification service is configured" do
    let(:app) { Fabricate(:app, :email_at_notices => [1], :notification_service => Fabricate(:campfire_notification_service)) }
    let(:err) { Fabricate(:err, :problem => Fabricate(:problem, :app => app, :notices_count => 100)) }

    before do
      Errbit::Config.per_app_email_at_notices = true
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    it "should create a campfire notification" do
      err.problem.stub(:notices_count).and_return(1)
      app.notification_service.stub!(:create_issue).and_return(true)
      app.notification_service.should_receive(:create_issue)

      Fabricate(:notice, :err => err)
    end
  end

end
