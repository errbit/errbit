require 'spec_helper'
require 'airbrake/version'
require 'airbrake/backtrace'
require 'airbrake/notice'

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
  context "with notice without line of backtrace" do
    let(:xml){
      Rails.root.join('spec','fixtures','hoptoad_test_notice.xml').read
    }

    let(:error_report) {
      ErrorReport.new(xml)
    }

    let!(:app) {
      Fabricate(
        :app,
        :api_key => 'APIKEY'
      )
    }

    describe "#app" do
      it 'find the good app' do
        expect(error_report.app).to eq app
      end
    end

    describe "#backtrace" do

      it 'should have valid backtrace' do
        error_report.backtrace.should be_valid
      end
    end

    describe "#generate_notice!" do
      it "save a notice" do
        expect {
          error_report.generate_notice!
        }.to change {
          app.reload.problems.count
        }.by(1)
      end
      context "with notice generate by Airbrake gem" do
        let(:xml) { Airbrake::Notice.new(
          :exception => Exception.new,
          :api_key => 'APIKEY',
          :project_root => Rails.root
        ).to_xml }
        it 'save a notice' do
          expect {
            error_report.generate_notice!
          }.to change {
            app.reload.problems.count
          }.by(1)
        end
      end

      describe "notice create" do
        before { error_report.generate_notice! }
        subject { error_report.notice }
        its(:message) { 'HoptoadTestingException: Testing hoptoad via "rake hoptoad:test". If you can see this, it works.' }
        its(:framework) { should == 'Rails: 3.2.11' }

        it 'has complete backtrace' do
          subject.backtrace_lines.size.should == 73
          subject.backtrace_lines.last['file'].should == '[GEM_ROOT]/bin/rake'
        end
        it 'has server_environement' do
          subject.server_environment['environment-name'].should == 'development'
        end

        it 'has request' do
          subject.request['url'].should == 'http://example.org/verify'
          subject.request['params']['controller'].should == 'application'
        end

        it 'has notifier' do
          subject.notifier['name'].should == 'Hoptoad Notifier'
        end

        it 'get user_attributes' do
          subject.user_attributes['id'].should == '123'
          subject.user_attributes['name'].should == 'Mr. Bean'
          subject.user_attributes['email'].should == 'mr.bean@example.com'
          subject.user_attributes['username'].should == 'mrbean'
        end
        it 'valid env_vars' do
        # XML: <var key="SCRIPT_NAME"/>
        subject.env_vars.should have_key('SCRIPT_NAME')
        subject.env_vars['SCRIPT_NAME'].should be_nil # blank ends up nil

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
          'secure'        => 'false',
          'httponly'      => 'true',
          'path'          => '/',
          'expire_after'  => nil,
          'domain'        => nil,
          'id'            => nil
        }
        subject.env_vars.should have_key('rack_session_options')
        subject.env_vars['rack_session_options'].should eql(expected)
      end
      end

      it 'save a notice assignes to err' do
        error_report.generate_notice!
        error_report.notice.err.should be_a(Err)
      end

      it 'memoize the notice' do
        expect {
          error_report.generate_notice!
          error_report.generate_notice!
        }.to change {
          Notice.count
        }.by(1)
      end

      it 'find the correct err for the notice' do
        err = Fabricate(:err, :problem => Fabricate(:problem, :resolved => true))
        
        ErrorReport.any_instance.stub(:fingerprint).and_return(err.fingerprint)
        
        expect {
          error_report.generate_notice!
        }.to change {
          error_report.error.resolved?
        }.from(true).to(false)
      end

      context "with notification service configured" do
        before do
          app.notify_on_errs = true
          app.watchers.build(:email => 'foo@example.com')
          app.save
        end
        it 'send email' do
          notice = error_report.generate_notice!
          email = ActionMailer::Base.deliveries.last
          email.to.should include(app.watchers.first.email)
          email.subject.should include(notice.message.truncate(50))
          email.subject.should include("[#{app.name}]")
          email.subject.should include("[#{notice.environment_name}]")
        end
      end

      context "with xml without request section" do
        let(:xml){
          Rails.root.join('spec','fixtures','hoptoad_test_notice_without_request_section.xml').read
        }
        it "save a notice" do
          expect {
            error_report.generate_notice!
          }.to change {
            app.reload.problems.count
          }.by(1)
        end
      end

      context "with xml with only a single line of backtrace" do
        let(:xml){
          Rails.root.join('spec','fixtures','hoptoad_test_notice_with_one_line_of_backtrace.xml').read
        }
        it "save a notice" do
          expect {
            error_report.generate_notice!
          }.to change {
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
          App.where(:api_key => app.api_key).delete_all
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

  end
end
