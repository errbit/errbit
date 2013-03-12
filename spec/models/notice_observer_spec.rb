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

  describe "should send a notification if a notification service is configured with defaults" do
    let(:app) { Fabricate(:app, :email_at_notices => [1], :notification_service => Fabricate(:campfire_notification_service))}
    let(:err) { Fabricate(:err, :problem => Fabricate(:problem, :app => app, :notices_count => 100)) }
    let(:backtrace) { Fabricate(:backtrace) }

    before do
      Errbit::Config.per_app_email_at_notices = true
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    it "should create a campfire notification" do
      app.notification_service.should_receive(:create_notification)

      Notice.create!(:err => err, :message => 'FooError: Too Much Bar', :server_environment => {'environment-name' => 'production'},
                     :backtrace => backtrace, :notifier => { 'name' => 'Notifier', 'version' => '1', 'url' => 'http://toad.com' })
    end
  end

  describe "should not send a notification if a notification service is not configured" do
    let(:app) { Fabricate(:app, :email_at_notices => [1], :notification_service => Fabricate(:notification_service))}
    let(:err) { Fabricate(:err, :problem => Fabricate(:problem, :app => app, :notices_count => 100)) }
    let(:backtrace) { Fabricate(:backtrace) }

    before do
      Errbit::Config.per_app_email_at_notices = true
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    it "should not create a campfire notification" do
      app.notification_service.should_not_receive(:create_notification)

      Notice.create!(:err => err, :message => 'FooError: Too Much Bar', :server_environment => {'environment-name' => 'production'},
                     :backtrace => backtrace, :notifier => { 'name' => 'Notifier', 'version' => '1', 'url' => 'http://toad.com' })
    end
  end

  describe 'hipcat notifications' do
    let(:app) { Fabricate(:app, :email_at_notices => [1], :notification_service => Fabricate(:hipchat_notification_service))}
    let(:err) { Fabricate(:err, :problem => Fabricate(:problem, :app => app, :notices_count => 100)) }

    before do
      Errbit::Config.per_app_email_at_notices = true
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    it 'creates a hipchat notification' do
      app.notification_service.should_receive(:create_notification)

      Fabricate(:notice, :err => err)
    end
  end
  
  describe "should send a notification at desired intervals" do
    let(:app) { Fabricate(:app, :email_at_notices => [1], :notification_service => Fabricate(:campfire_notification_service, :notify_at_notices => [1,2]))}
    let(:backtrace) { Fabricate(:backtrace) }

    before do
      Errbit::Config.per_app_email_at_notices = true
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    it "should create a campfire notification on first notice" do
      err = Fabricate(:err, :problem => Fabricate(:problem, :app => app, :notices_count => 1))
      app.notification_service.should_receive(:create_notification)

      Notice.create!(:err => err, :message => 'FooError: Too Much Bar', :server_environment => {'environment-name' => 'production'},
                     :backtrace => backtrace, :notifier => { 'name' => 'Notifier', 'version' => '1', 'url' => 'http://toad.com' })
    end

    it "should create a campfire notification on second notice" do
      err = Fabricate(:err, :problem => Fabricate(:problem, :app => app, :notices_count => 1))
      app.notification_service.should_receive(:create_notification)

      Notice.create!(:err => err, :message => 'FooError: Too Much Bar', :server_environment => {'environment-name' => 'production'},
                     :backtrace => backtrace, :notifier => { 'name' => 'Notifier', 'version' => '1', 'url' => 'http://toad.com' })
    end

    it "should not create a campfire notification on third notice" do
      err = Fabricate(:err, :problem => Fabricate(:problem, :app => app, :notices_count => 1))
      app.notification_service.should_receive(:create_notification)

      Notice.create!(:err => err, :message => 'FooError: Too Much Bar', :server_environment => {'environment-name' => 'production'},
                     :backtrace => backtrace, :notifier => { 'name' => 'Notifier', 'version' => '1', 'url' => 'http://toad.com' })
    end
  end
end
