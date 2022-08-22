require 'airbrake/version'
require 'airbrake/backtrace'
require 'airbrake/notice'
require 'airbrake/utils/params_cleaner'

# MonkeyPatch to instanciate a Airbrake::Notice without configure
# Airbrake
#
module Airbrake
  API_VERSION = '2.4'

  class Notice
    def framework
      'rails'
    end
  end
end

describe ErrorReport do
  let(:xml) do
    Rails.root.join('spec', 'fixtures', 'hoptoad_test_notice.xml').read
  end

  let(:error_report) { ErrorReport.new(xml) }

  let!(:app) do
    Fabricate(
      :app,
      api_key: 'APIKEY'
    )
  end

  describe "#app" do
    it 'find the good app' do
      expect(error_report.app).to eq app
    end
  end

  describe "#backtrace" do
    it 'should have valid backtrace' do
      expect(error_report.backtrace).to be_valid
    end
  end

  describe "#generate_notice!" do
    it "save a notice" do
      expect do
        error_report.generate_notice!
      end.to change {
        app.reload.problems.count
      }.by(1)
    end

    context "with a minimal notice" do
      let(:xml) do
        Rails.root.join('spec', 'fixtures', 'minimal_test_notice.xml').read
      end

      it 'save a notice' do
        expect do
          error_report.generate_notice!
        end.to change {
          app.reload.problems.count
        }.by(1)
      end
    end

    context "with notice generate by Airbrake gem" do
      let(:xml) do
        Airbrake::Notice.new(
          exception:    Exception.new,
          api_key:      'APIKEY',
          project_root: Rails.root
        ).to_xml
      end
      it 'save a notice' do
        expect do
          error_report.generate_notice!
        end.to change {
          app.reload.problems.count
        }.by(1)
      end
    end

    describe "notice create" do
      before { error_report.generate_notice! }
      subject { error_report.notice }

      it 'has correct message' do
        expect(subject.message).to include('HoptoadTestingException: Testing hoptoad via "rake hoptoad:test". If you can see this, it works')
      end

      it 'has correct framework' do
        expect(subject.framework).to eq('Rails: 3.2.11')
      end

      it 'has complete backtrace' do
        expect(subject.backtrace_lines.size).to eq 73
        expect(subject.backtrace_lines.last['file']).to eq '[GEM_ROOT]/bin/rake'
      end

      it 'has server_environement' do
        expect(subject.server_environment['environment-name']).to eq 'development'
      end

      it 'has request' do
        expect(subject.request['url']).to eq 'http://example.org/verify/cupcake=fistfight&lovebird=doomsayer'
        expect(subject.request['params']['controller']).to eq 'application'
      end

      it 'has notifier' do
        expect(subject.notifier['name']).to eq 'Hoptoad Notifier'
      end

      it 'get user_attributes' do
        expect(subject.user_attributes['id']).to eq '123'
        expect(subject.user_attributes['name']).to eq 'Mr. Bean'
        expect(subject.user_attributes['email']).to eq 'mr.bean@example.com'
        expect(subject.user_attributes['username']).to eq 'mrbean'
      end

      it 'valid env_vars' do
        # XML: <var key="SCRIPT_NAME"/>
        expect(subject.env_vars).to have_key('SCRIPT_NAME')
        expect(subject.env_vars['SCRIPT_NAME']).to be_nil # blank ends up nil

        # XML representation:
        # <var key="rack.session.options">
        #   <var key="secure">false</var>
        #   <var key="httponly">true</var>
        #   <var key="path">/</var>
        #   <var key="expire_after"/>
        #   <var key="domain"/>
        #   <var key="id"/>
        # </var>
        expected = {
          'secure'       => 'false',
          'httponly'     => 'true',
          'path'         => '/',
          'expire_after' => nil,
          'domain'       => nil,
          'id'           => nil
        }
        expect(subject.env_vars).to have_key('rack_session_options')
        expect(subject.env_vars['rack_session_options']).to eql(expected)
      end
    end
  end

  describe '#cache_attributes_on_problem' do
    it 'sets the latest notice properties on the problem' do
      error_report.generate_notice!
      problem = error_report.problem.reload
      notice = error_report.notice.reload

      expect(problem.environment).to eq('development')
      expect(problem.error_class).to eq('HoptoadTestingException')
      expect(problem.last_notice_at).to eq(notice.created_at)
      expect(problem.message).to eq(notice.message)
      expect(problem.where).to eq(notice.where)
    end

    it 'unresolves the problem' do
      error_report.generate_notice!
      problem = error_report.problem
      problem.update(
        resolved_at: Time.zone.now,
        resolved:    true
      )

      error_report = ErrorReport.new(xml)
      error_report.generate_notice!
      problem.reload

      expect(problem.resolved_at).to be(nil)
      expect(problem.resolved).to be(false)
    end

    it 'caches notice counts' do
      error_report.generate_notice!
      problem = error_report.problem
      problem.reload

      expect(problem.notices_count).to be(1)
      expect(problem.user_agents['382b0f5185773fa0f67a8ed8056c7759']['count']).to be(1)
      expect(problem.messages['9449f087eee0499e2d9029ae3dacaf53']['count']).to be(1)
      expect(problem.hosts['1bdf72e04d6b50c82a48c7e4dd38cc69']['count']).to be(1)
    end

    it 'increments notice counts' do
      error_report.generate_notice!
      error_report = ErrorReport.new(xml)
      error_report.generate_notice!
      problem = error_report.problem
      problem.reload

      expect(problem.notices_count).to be(2)
      expect(problem.user_agents['382b0f5185773fa0f67a8ed8056c7759']['count']).to be(2)
      expect(problem.messages['9449f087eee0499e2d9029ae3dacaf53']['count']).to be(2)
      expect(problem.hosts['1bdf72e04d6b50c82a48c7e4dd38cc69']['count']).to be(2)
    end
  end

  it 'save a notice assignes to err' do
    error_report.generate_notice!
    expect(error_report.notice.err).to be_a(Err)
  end

  it 'memoize the notice' do
    expect do
      error_report.generate_notice!
      error_report.generate_notice!
    end.to change {
      Notice.count
    }.by(1)
  end

  it 'find the correct err for the notice' do
    error_report.generate_notice!
    error_report.problem.resolve!

    expect do
      ErrorReport.new(xml).generate_notice!
    end.to change {
      error_report.problem.reload.resolved?
    }.from(true).to(false)
  end

  context "with notification service configured" do
    before do
      app.notify_on_errs = true
      app.save
      watcher = app.watchers.build(email: 'foo@example.com')
      watcher.save
      # TODO: uncomment with new mongoid 6.2.x or later
      # app.watchers.build(email: 'foo@example.com')
      # app.save
    end

    it 'send email' do
      notice = error_report.generate_notice!
      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include(app.watchers.first.email)
      expect(email.subject).to include(notice.message.truncate(50))
      expect(email.subject).to include("[#{app.name}]")
      expect(email.subject).to include("[#{notice.environment_name}]")
    end

    context 'when email_at_notices config is specified', type: :mailer do
      before do
        allow(Errbit::Config).to receive(:email_at_notices).and_return(email_at_notices)
      end

      context 'as [0]' do
        let(:email_at_notices) { [0] }

        it "sends email on 1st occurrence" do
          1.times { described_class.new(xml).generate_notice! }
          expect(ActionMailer::Base.deliveries.length).to eq(1)
        end

        it "sends email on 2nd occurrence" do
          2.times { described_class.new(xml).generate_notice! }
          expect(ActionMailer::Base.deliveries.length).to eq(2)
        end

        it "sends email on 3rd occurrence" do
          3.times { described_class.new(xml).generate_notice! }
          expect(ActionMailer::Base.deliveries.length).to eq(3)
        end
      end

      context "as [1,3]" do
        let(:email_at_notices) { [1, 3] }

        it "sends email on 1st occurrence" do
          1.times { described_class.new(xml).generate_notice! }
          expect(ActionMailer::Base.deliveries.length).to eq(1)
        end

        it "does not send email on 2nd occurrence" do
          2.times { described_class.new(xml).generate_notice! }
          expect(ActionMailer::Base.deliveries.length).to eq(1)
        end

        it "sends email on 3rd occurrence" do
          3.times { described_class.new(xml).generate_notice! }
          expect(ActionMailer::Base.deliveries.length).to eq(2)
        end

        it "sends email on all occurrences when problem was resolved" do
          3.times do
            notice = described_class.new(xml).generate_notice!
            notice.problem.resolve!
          end
          expect(ActionMailer::Base.deliveries.length).to eq(3)
        end
      end
    end

    context "with xml without request section" do
      let(:xml) do
        Rails.root.join('spec', 'fixtures', 'hoptoad_test_notice_without_request_section.xml').read
      end
      it "save a notice" do
        expect do
          error_report.generate_notice!
        end.to change {
          app.reload.problems.count
        }.by(1)
      end
    end

    context "with xml with only a single line of backtrace" do
      let(:xml) do
        Rails.root.join('spec', 'fixtures', 'hoptoad_test_notice_with_one_line_of_backtrace.xml').read
      end
      it "save a notice" do
        expect do
          error_report.generate_notice!
        end.to change {
          app.reload.problems.count
        }.by(1)
      end
    end
  end

  describe "#valid?" do
    context "with valid error report" do
      it "return true" do
        expect(error_report.valid?).to be true
      end
    end
    context "with not valid api_key" do
      before do
        App.where(api_key: app.api_key).delete_all
      end
      it "return false" do
        expect(error_report.valid?).to be false
      end
    end
  end

  describe "#notice" do
    context "before generate_notice!" do
      it 'return nil' do
        expect(error_report.notice).to be nil
      end
    end

    context "after generate_notice!" do
      before do
        error_report.generate_notice!
      end

      it 'return the notice' do
        expect(error_report.notice).to be_a Notice
      end
    end
  end

  describe "#should_keep?" do
    context "with current app version not set" do
      before do
        error_report.app.current_app_version = nil
        error_report.server_environment['app-version'] = '1.0'
      end

      it "return true" do
        expect(error_report.should_keep?).to be true
      end
    end

    context "with current app version set" do
      before do
        error_report.app.current_app_version = '1.0'
      end

      it "return true if current or newer" do
        error_report.server_environment['app-version'] = '1.0'
        expect(error_report.should_keep?).to be true
      end

      it "return false if older" do
        error_report.server_environment['app-version'] = '0.9'
        expect(error_report.should_keep?).to be false
      end
    end
  end
end
