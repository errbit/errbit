require 'spec_helper'

describe Watcher do
  
  context 'validations' do
    it 'requires an email address' do
      watcher = Factory.build(:watcher, :email => nil)
      watcher.should_not be_valid
      watcher.errors[:email].should include("can't be blank")
    end
  end
  
end
