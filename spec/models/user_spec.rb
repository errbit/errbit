require 'spec_helper'

describe User do
  
  context 'validations' do
    it 'require that a name is present' do
      user = Factory.build(:user, :name => nil)
      user.should_not be_valid
      user.errors[:name].should include("can't be blank")
    end
  end
  
  context 'Watchers' do
    
    it 'has many watchers' do
      user = Factory(:user)
      watcher = Factory(:watcher, :user => user, :email => nil)
      user.watchers.should_not be_empty
      user.watchers.should include(watcher)
    end
    
    it "destroys any related watchers when it is destroyed" do
      user = Factory(:user)
      app  = Factory(:app)
      watcher = Factory(:watcher, :app => app, :user => user, :email => nil)
      user.watchers.should_not be_empty
      user.destroy
      app.reload.watchers.should_not include(watcher)
    end
    
    it "has many apps through watchers" do
      user = Factory(:user)
      watched_app  = Factory(:app)
      unwatched_app = Factory(:app)
      watcher = Factory(:watcher, :app => watched_app, :user => user, :email => nil)
      user.apps.all.should include(watched_app)
      user.apps.all.should_not include(unwatched_app)
    end
    
  end
  
end
