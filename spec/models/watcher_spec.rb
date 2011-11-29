require 'spec_helper'

describe Watcher do

  context 'validations' do
    it 'requires an email address or an associated user' do
      watcher = Fabricate.build(:watcher, :email => nil, :user => nil)
      watcher.should_not be_valid
      watcher.errors[:base].should include("You must specify either a user or an email address")

      watcher.email = 'watcher@example.com'
      watcher.should be_valid

      watcher.email = nil
      watcher.should_not be_valid

      watcher.user = Fabricate(:user)
      watcher.watcher_type = 'user'
      watcher.should be_valid
    end
  end

  context 'address' do
    it "returns the user's email address if there is a user" do
      user = Fabricate(:user, :email => 'foo@bar.com')
      watcher = Fabricate(:user_watcher, :user => user)
      watcher.address.should == 'foo@bar.com'
    end

    it "returns the email if there is no user" do
      watcher = Fabricate(:watcher, :email => 'widgets@acme.com')
      watcher.address.should == 'widgets@acme.com'
    end
  end

end

