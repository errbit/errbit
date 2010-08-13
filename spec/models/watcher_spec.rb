require 'spec_helper'

describe Watcher do
  
  context 'validations' do
    it 'requires an email address or an associated user' do
      watcher = Factory.build(:watcher, :email => nil, :user => nil)
      watcher.should_not be_valid
      watcher.errors[:base].should include("You must specify either a user or an email address")
      
      watcher.email = 'watcher@example.com'
      watcher.should be_valid
      
      watcher.email = nil
      watcher.should_not be_valid
      
      watcher.user = Factory(:user)
      watcher.should be_valid
    end
    
    
  end
  
end
