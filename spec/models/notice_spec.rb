require 'spec_helper'

describe Notice do

  context 'validations' do
    it 'requires a backtrace' do
      notice = Factory.build(:notice, :backtrace => nil)
      notice.should_not be_valid
      notice.errors[:backtrace].should include("can't be blank")
    end

    it 'requires the server_environment' do
      notice = Factory.build(:notice, :server_environment => nil)
      notice.should_not be_valid
      notice.errors[:server_environment].should include("can't be blank")
    end

    it 'requires the notifier' do
      notice = Factory.build(:notice, :notifier => nil)
      notice.should_not be_valid
      notice.errors[:notifier].should include("can't be blank")
    end
  end

  context '.in_app_backtrace_line?' do
    let(:backtrace) do [{
        'number'  => rand(999),
        'file'    => '[GEM_ROOT]/gems/actionpack-3.0.4/lib/action_controller/metal/rescue.rb',
        'method'  => ActiveSupport.methods.shuffle.first
      }, {
        'number'  => rand(999),
        'file'    => '[PROJECT_ROOT]/vendor/plugins/seamless_database_pool/lib/seamless_database_pool/controller_filter.rb',
        'method'  => ActiveSupport.methods.shuffle.first
      }, {
        'number'  => rand(999),
        'file'    => '[PROJECT_ROOT]/lib/set_headers.rb',
        'method'  => ActiveSupport.methods.shuffle.first
      }]
    end

    it "should be false for line not starting with PROJECT_ROOT" do
      Notice.in_app_backtrace_line?(backtrace[0]).should == false
    end

    it "should be false for file in vendor dir" do
      Notice.in_app_backtrace_line?(backtrace[1]).should == false
    end

    it "should be true for application file" do
      Notice.in_app_backtrace_line?(backtrace[2]).should == true
    end
  end

  context '#from_xml' do
    before do
      @xml = Rails.root.join('spec','fixtures','hoptoad_test_notice.xml').read
      @app = Factory(:app, :api_key => 'APIKEY')
      Digest::MD5.stub(:hexdigest).and_return('fingerprintdigest')
    end

    it 'finds the correct app' do
      @notice = Notice.from_xml(@xml)
      @notice.err.app.should == @app
    end

    it 'finds the correct err for the notice' do
      Err.should_receive(:for).with({
        :app      => @app,
        :klass        => 'HoptoadTestingException',
        :component    => 'application',
        :action       => 'verify',
        :environment  => 'development',
        :fingerprint  => 'fingerprintdigest'
      }).and_return(err = Factory(:err))
      err.notices.stub(:create!)
      @notice = Notice.from_xml(@xml)
    end

    it 'marks the err as unresolve if it was previously resolved' do
      Err.should_receive(:for).with({
        :app      => @app,
        :klass        => 'HoptoadTestingException',
        :component    => 'application',
        :action       => 'verify',
        :environment  => 'development',
        :fingerprint  => 'fingerprintdigest'
      }).and_return(err = Factory(:err, :resolved => true))
      err.should be_resolved
      @notice = Notice.from_xml(@xml)
      @notice.err.should == err
      @notice.err.should_not be_resolved
    end

    it 'should create a new notice' do
      @notice = Notice.from_xml(@xml)
      @notice.should be_persisted
    end

    it 'assigns an err to the notice' do
      @notice = Notice.from_xml(@xml)
      @notice.err.should be_a(Err)
    end

    it 'captures the err message' do
      @notice = Notice.from_xml(@xml)
      @notice.message.should == 'HoptoadTestingException: Testing hoptoad via "rake hoptoad:test". If you can see this, it works.'
    end

    it 'captures the backtrace' do
      @notice = Notice.from_xml(@xml)
      @notice.backtrace.size.should == 73
      @notice.backtrace.last['file'].should == '[GEM_ROOT]/bin/rake'
    end

    it 'captures the server_environment' do
      @notice = Notice.from_xml(@xml)
      @notice.server_environment['environment-name'].should == 'development'
    end

    it 'captures the request' do
      @notice = Notice.from_xml(@xml)
      @notice.request['url'].should == 'http://example.org/verify'
      @notice.request['params']['controller'].should == 'application'
    end

    it 'captures the notifier' do
      @notice = Notice.from_xml(@xml)
      @notice.notifier['name'].should == 'Hoptoad Notifier'
    end

    it "should handle params without 'request' section" do
      @xml = Rails.root.join('spec','fixtures','hoptoad_test_notice_without_request_section.xml').read
      lambda { Notice.from_xml(@xml) }.should_not raise_error
    end

    it "should raise ApiVersionError" do
      @xml = Rails.root.join('spec', 'fixtures', 'hoptoad_test_notice_with_wrong_version.xml').read
      expect { Notice.from_xml(@xml)  }.to raise_error(Hoptoad::V2::ApiVersionError)
    end
  end

  describe "key sanitization" do
    before do
      @hash = { "some.key" => { "$nested.key" => {"$Path" => "/", "some$key" => "key"}}}
      @hash_sanitized = { "some&#46;key" => { "&#36;nested&#46;key" => {"&#36;Path" => "/", "some$key" => "key"}}}
    end
    [:server_environment, :request, :notifier].each do |key|
      it "replaces . with &#46; and $ with &#36; in keys used in #{key}" do
        err = Factory(:err)
        notice = Factory(:notice, :err => err, key => @hash)
        notice.send(key).should == @hash_sanitized
      end
    end
  end

  describe "user agent" do
    it "should be parsed and human-readable" do
      notice = Factory.build(:notice, :request => {'cgi-data' => {'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.204 Safari/534.16'}})
      notice.user_agent.browser.should == 'Chrome'
      notice.user_agent.version.to_s.should =~ /^10\.0/
    end

    it "should be nil if HTTP_USER_AGENT is blank" do
      notice = Factory.build(:notice)
      notice.user_agent.should == nil
    end
  end

  describe "email notifications (configured individually for each app)" do
    custom_thresholds = [2, 4, 8, 16, 32, 64]

    before do
      Errbit::Config.per_app_email_at_notices = true
      @app = Factory(:app_with_watcher, :email_at_notices => custom_thresholds)
      @err = Factory(:err, :app => @app)
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    custom_thresholds.each do |threshold|
      it "sends an email notification after #{threshold} notice(s)" do
        @err.notices.stub(:count).and_return(threshold)
        Mailer.should_receive(:err_notification).
          and_return(mock('email', :deliver => true))
        Factory(:notice, :err => @err)
      end
    end
  end

end

