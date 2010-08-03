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
    end
    
    it 'finds the correct error for the notice' do
      Error.should_receive(:for).with({
        :klass        => 'HoptoadTestingException',
        :message      => 'HoptoadTestingException: Testing hoptoad via "rake hoptoad:test". If you can see this, it works.',
        :component    => 'application',
        :action       => 'verify',
        :environment  => 'development'
      }).and_return(err = Error.new)
      err.notices.stub(:create)
      @notice = Notice.from_xml(@xml)
    end
    
    it 'should create a new notice' do
      @notice = Notice.from_xml(@xml)
      @notice.should be_persisted
    end
    
    it 'assigns an error to the notice' do
      @notice = Notice.from_xml(@xml)
      @notice.error.should be_an(Error)
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
  
end