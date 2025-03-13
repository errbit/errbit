describe "Callback on Notice", type: "model" do
  let(:notice_attrs_for) do
    lambda do |api_key|
      {
        error_class: "HoptoadTestingException",
        message: "some message",
        backtrace: [
          {
            "number" => "425",
            "file" => "[GEM_ROOT]/callbacks.rb",
            "method" => "__callbacks"
          }
        ],
        request: {"component" => "application"},
        server_environment: {
          "project-root" => "/path/to/sample/project",
          "environment-name" => "development"
        },
        api_key: api_key,
        notifier: {
          "name" => "Hoptoad Notifier",
          "version" => "2.3.2",
          "url" => "http://hoptoadapp.com"
        },
        framework: "Rails: 3.2.11"
      }
    end
  end

  describe "email notifications (configured individually for each app)" do
    let(:notice_attrs) { notice_attrs_for.call(app.api_key) }
    custom_thresholds = [2, 4, 8, 16, 32, 64]
    let(:app) do
      Fabricate(:app_with_watcher, email_at_notices: custom_thresholds)
    end

    before do
      Errbit::Config.per_app_email_at_notices = true
      error_report = ErrorReport.new(notice_attrs)
      error_report.generate_notice!
      @problem = error_report.notice.err.problem
    end

    after { Errbit::Config.per_app_email_at_notices = false }

    custom_thresholds.each do |threshold|
      it "sends an email notification after #{threshold} notice(s)" do
        # set to just before the threshold
        @problem.update_attributes notices_count: threshold - 1

        expect(Mailer).to receive(:err_notification)
          .and_return(double("email", deliver_now: true))

        error_report = ErrorReport.new(notice_attrs)
        error_report.generate_notice!
      end
    end

    it "doesn't email after 5 notices" do
      @problem.update_attributes notices_count: 5

      expect(Mailer).to_not receive(:err_notification)

      error_report = ErrorReport.new(notice_attrs)
      error_report.generate_notice!
    end

    it "notify self if mailer fails" do
      expect(Mailer).to receive(:err_notification).and_raise(ArgumentError)
      expect(HoptoadNotifier).to receive(:notify)
      ErrorReport.new(notice_attrs).generate_notice!
    end
  end

  describe "email notifications for resolved issues" do
    let(:notification_service) { Fabricate(:campfire_notification_service) }
    let(:app) do
      Fabricate(
        :app_with_watcher,
        notify_on_errs: true,
        email_at_notices: [1, 100]
      )
    end
    let(:notice_attrs) { notice_attrs_for.call(app.api_key) }

    before { Errbit::Config.per_app_email_at_notices = true }
    after { Errbit::Config.per_app_email_at_notices = false }

    it "sends email the first time after the error is resolved" do
      error_report = ErrorReport.new(notice_attrs)
      error_report.generate_notice!
      err = error_report.notice.err

      err.problem.update_attributes notices_count: 99
      err.problem.resolve!

      expect(Mailer).to receive(:err_notification)
        .and_return(double("email", deliver_now: true))

      ErrorReport.new(notice_attrs).generate_notice!
    end
  end

  describe "send email when notification service is configured but fails" do
    let(:notification_service) { Fabricate(:campfire_notification_service) }
    let(:app) do
      Fabricate(
        :app_with_watcher,
        notify_on_errs: true,
        notification_service: notification_service
      )
    end
    let(:notice_attrs) { notice_attrs_for.call(app.api_key) }

    before { Errbit::Config.per_app_notify_at_notices = true }
    after { Errbit::Config.per_app_notify_at_notices = false }

    it "sends email" do
      error_report = ErrorReport.new(notice_attrs)

      expect(error_report.app.notification_service)
        .to receive(:create_notification).and_raise(ArgumentError)
      expect(Mailer)
        .to receive(:err_notification).and_return(double(deliver_now: true))

      error_report.generate_notice!
    end
  end

  describe "should not send a notification if a notification service is not" \
           "configured" do
    let(:notification_service) { Fabricate(:notification_service) }
    let(:app) { Fabricate(:app, notification_service: notification_service) }
    let(:notice_attrs) { notice_attrs_for.call(app.api_key) }

    before { Errbit::Config.per_app_notify_at_notices = true }
    after { Errbit::Config.per_app_notify_at_notices = false }

    it "should not create a campfire notification" do
      error_report = ErrorReport.new(notice_attrs)
      expect(error_report.app.notification_service).to_not receive(:create_notification)
      error_report.generate_notice!
    end
  end

  describe "should send a notification at desired intervals" do
    let(:notification_service) do
      Fabricate(:campfire_notification_service, notify_at_notices: [1, 2])
    end
    let(:app) { Fabricate(:app, notification_service: notification_service) }
    let(:notice_attrs) { notice_attrs_for.call(app.api_key) }

    before { Errbit::Config.per_app_notify_at_notices = true }
    after { Errbit::Config.per_app_notify_at_notices = false }

    it "should create a campfire notification on first notice" do
      error_report = ErrorReport.new(notice_attrs)
      expect(error_report.app.notification_service)
        .to receive(:create_notification)
      error_report.generate_notice! # one
    end

    it "should create a campfire notification on second notice" do
      ErrorReport.new(notice_attrs).generate_notice! # one
      error_report = ErrorReport.new(notice_attrs)
      expect(error_report.app.notification_service)
        .to receive(:create_notification)
      error_report.generate_notice! # two
    end

    it "should not create a campfire notification on third notice" do
      ErrorReport.new(notice_attrs).generate_notice! # one
      ErrorReport.new(notice_attrs).generate_notice! # two
      error_report = ErrorReport.new(notice_attrs)
      expect(error_report.app.notification_service)
        .to_not receive(:create_notification)
      error_report.generate_notice! # three
    end

    it "should create a campfire notification when problem was resolved" do
      ErrorReport.new(notice_attrs).generate_notice! # one
      notice = ErrorReport.new(notice_attrs).generate_notice! # two
      notice.problem.resolve!
      error_report = ErrorReport.new(notice_attrs)
      expect(error_report.app.notification_service)
        .to receive(:create_notification)
      error_report.generate_notice! # three
    end
  end
end
