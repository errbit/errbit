require 'spec_helper'

describe "When a Notice is created" do
  describe "for a resolved issue" do
    before do
      @app = Fabricate(:app)
      @problem = Fabricate(:problem, app: @app, opened_at: 3.days.ago)
      @err = Fabricate(:err, problem: @problem)
      @problem.resolve!
    end

    it "should unresolve the problem" do
      Fabricate(:notice, err: @err)
      expect(@problem.reload.resolved).to be(false)
    end

    it "should set the problems opened timestamp" do
      expect { Fabricate(:notice, err: @err) }.to change(@problem, :opened_at)
    end
  end



  describe "email notifications" do
    before do
      Errbit::Config.per_app_email_at_notices = true
      @app = Fabricate(:app_with_watcher, email_at_notices: [1])
      @problem = Fabricate(:problem, app: @app)
      @err = Fabricate(:err, problem: @problem)
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    describe "configured individually for each app" do
      custom_thresholds = [2, 4, 8, 16, 32, 64]

      before do
        @app.stub(:email_at_notices).and_return(custom_thresholds)
      end

      custom_thresholds.each do |threshold|
        it "should be sent after #{threshold} notice(s)" do
          @err.problem.stub(:notices_since_reopened).and_return(threshold)
          expect(Mailer).to receive(:err_notification).
            and_return(double('email', deliver: true))
          Fabricate(:notice, err: @err)
        end
      end
    end

    describe "for a resolved issue" do
      before do
        @problem.resolve!
      end

      it "should be sent after (n) notices since the problem was reopened" do
        expect(Mailer).to receive(:err_notification).
          and_return(double('email', deliver: true))
        Fabricate(:notice, err: @err)
      end
    end

    describe "that raise an exception during delivery" do
      before do
        expect(Mailer).to receive(:err_notification).and_raise(ArgumentError)
      end

      it "should be reported for Self.Errbit" do
        expect(HoptoadNotifier).to receive(:notify)
        Fabricate(:notice, err: @err)
      end

      it "should not be reported for Self.Errbit when the notice is being reported is a delivery failure" do
        @app.stub(:name).and_return("Self.Errbit")
        HoptoadNotifier.stub(:notify)
        Fabricate(:notice, err: @err, :backtrace =>
          Fabricate(:backtrace, lines: [
            Fabricate(:backtrace_line, file: "[PROJECT_ROOT]/app/models/notice.rb", method: "email_notification")
          ]))
        expect(HoptoadNotifier).to_not have_received(:notify)
      end
    end
  end



  describe "service notifications" do
    let(:app) { Fabricate(:app, email_at_notices: [1], notification_service: Fabricate(:campfire_notification_service))}
    let(:err) { Fabricate(:err, problem: Fabricate(:problem, app: app)) }

    before do
      Errbit::Config.per_app_email_at_notices = true
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    describe "configured with defaults" do
      it "should create a campfire notification" do
        expect(app.notification_service).to receive(:create_notification)
        Fabricate(:notice, err: err)
      end
    end

    describe "configured with defaults but failed" do
      let(:app) { Fabricate(:app_with_watcher,
                            notify_on_errs: true,
                            email_at_notices: [1, 100], notification_service: Fabricate(:campfire_notification_service))}

      it "send email" do
        expect(app.notification_service).to receive(:create_notification).and_raise(ArgumentError)
        expect(Mailer).to receive(:err_notification).and_return(double(deliver: true))
        Fabricate(:notice, err: err)
      end
    end

    describe "that are not configured" do
      let(:app) { Fabricate(:app, email_at_notices: [1], notification_service: Fabricate(:notification_service))}

      it "should not create a campfire notification" do
        expect(app.notification_service).to_not receive(:create_notification)
        Fabricate(:notice, err: err)
      end
    end
    
    describe "should send a notification at desired intervals" do
      let(:app) { Fabricate(:app, email_at_notices: [1], notification_service: Fabricate(:campfire_notification_service, notify_at_notices: [1,2]))}

      it "should create a campfire notification on first notice" do
        err = Fabricate(:err, problem: Fabricate(:problem, app: app))
        expect(app.notification_service).to receive(:create_notification)
        Fabricate(:notice, err: err)
      end

      it "should create a campfire notification on second notice" do
        err = Fabricate(:err, problem: Fabricate(:problem, app: app))
        expect(app.notification_service).to receive(:create_notification)
        Fabricate(:notice, err: err)
      end

      it "should not create a campfire notification on third notice" do
        err = Fabricate(:err, problem: Fabricate(:problem, app: app))
        expect(app.notification_service).not_to receive(:create_notification)
        Fabricate(:notice, err: err)
      end
    end
    
    describe "that raise an exception during delivery" do
      before do
        @app = Fabricate(:app, email_at_notices: [1], notification_service: Fabricate(:campfire_notification_service))
        @err = Fabricate(:err, problem: Fabricate(:problem, app: @app))
        expect(@app.notification_service).to receive(:create_notification).and_raise(ArgumentError)
      end

      it "should be reported for Self.Errbit" do
        expect(HoptoadNotifier).to receive(:notify)
        Fabricate(:notice, err: @err)
      end

      it "should not be reported for Self.Errbit when the notice is being reported is a delivery failure" do
        @app.stub(:name).and_return("Self.Errbit")
        HoptoadNotifier.stub(:notify)
        Fabricate(:notice, err: @err, :backtrace =>
          Fabricate(:backtrace, lines: [
            Fabricate(:backtrace_line, file: "[PROJECT_ROOT]/app/models/notice.rb", method: "services_notification")
          ]))
        expect(HoptoadNotifier).to_not have_received(:notify)
      end
    end
  end



  describe 'hipcat notifications' do
    let(:app) { Fabricate(:app, email_at_notices: [1], notification_service: Fabricate(:hipchat_notification_service))}
    let(:err) { Fabricate(:err, problem: Fabricate(:problem, app: app)) }

    before do
      Errbit::Config.per_app_email_at_notices = true
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    it 'creates a hipchat notification' do
      expect(app.notification_service).to receive(:create_notification)

      Fabricate(:notice, err: err)
    end
  end

end
