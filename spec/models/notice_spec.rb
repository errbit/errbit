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
      @err = Factory(:err, :problem => Factory(:problem, :app => @app))
    end

    after do
      Errbit::Config.per_app_email_at_notices = false
    end

    custom_thresholds.each do |threshold|
      it "sends an email notification after #{threshold} notice(s)" do
        @err.problem.stub(:notices_count).and_return(threshold)
        Mailer.should_receive(:err_notification).
          and_return(mock('email', :deliver => true))
        Factory(:notice, :err => @err)
      end
    end
  end


end

