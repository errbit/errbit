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
  
  context '#from_xml' do
    before do
      @xml = Rails.root.join('spec','fixtures','hoptoad_test_notice.xml').read
      @project = Factory(:project, :api_key => 'ALLGLORYTOTHEHYPNOTOAD')
      Digest::MD5.stub(:hexdigest).and_return('fingerprintdigest')
    end
    
    it 'finds the correct project' do
      @notice = Notice.from_xml(@xml)
      @notice.err.project.should == @project
    end
    
    it 'finds the correct error for the notice' do
      Err.should_receive(:for).with({
        :project      => @project,
        :klass        => 'HoptoadTestingException',
        :component    => 'application',
        :action       => 'verify',
        :environment  => 'development',
        :fingerprint  => 'fingerprintdigest'
      }).and_return(err = Err.new)
      err.notices.stub(:create!)
      @notice = Notice.from_xml(@xml)
    end
    
    it 'should create a new notice' do
      @notice = Notice.from_xml(@xml)
      @notice.should be_persisted
    end
    
    it 'assigns an error to the notice' do
      @notice = Notice.from_xml(@xml)
      @notice.err.should be_a(Err)
    end
    
    it 'captures the error message' do
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
  end
  
  describe "email notifications" do
    before do
      @project = Factory(:project_with_watcher)
      @error = Factory(:err, :project => @project)
    end
    
    App.email_at_notices.each do |threshold|
      it "sends an email notification after #{threshold} notice(s)" do
        @error.notices.stub(:count).and_return(threshold)
        Mailer.should_receive(:error_notification).
          and_return(mock('email', :deliver => true))
        Factory(:notice, :err => @error)
      end
    end
  end
  
end