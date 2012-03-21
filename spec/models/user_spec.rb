require 'spec_helper'

describe User do

  context 'validations' do
    it 'require that a name is present' do
      user = Fabricate.build(:user, :name => nil)
      user.should_not be_valid
      user.errors[:name].should include("can't be blank")
    end

    it 'requires password without github login' do
      user = Fabricate.build(:user, :password => nil)
      user.should_not be_valid
      user.errors[:password].should include("can't be blank")
    end

    it "doesn't require password with github login" do
      user = Fabricate.build(:user, :password => nil, :github_login => 'nashby')
      user.should be_valid
    end
  end

  describe '.find_for_github_oauth' do
    let(:auth_hash) { Hashie::Mash.new(:provider => 'github', :extra => { :raw_info => { :login => 'nashby' } }) }

    it 'finds user by github login' do
      user = Fabricate(:user, :github_login => 'nashby')
      User.find_for_github_oauth(auth_hash).should == user
    end
  end

  context 'Watchers' do

    it 'has many watchers' do
      user = Fabricate(:user)
      watcher = Fabricate(:user_watcher, :user => user)
      user.watchers.should_not be_empty
      user.watchers.should include(watcher)
    end

    it "destroys any related watchers when it is destroyed" do
      user = Fabricate(:user)
      app  = Fabricate(:app)
      watcher = Fabricate(:user_watcher, :app => app, :user => user)
      user.watchers.should_not be_empty
      user.destroy
      app.reload.watchers.should_not include(watcher)
    end

    it "has many apps through watchers" do
      user = Fabricate(:user)
      watched_app  = Fabricate(:app)
      unwatched_app = Fabricate(:app)
      watcher = Fabricate(:user_watcher, :app => watched_app, :user => user)
      user.apps.all.should include(watched_app)
      user.apps.all.should_not include(unwatched_app)
    end

  end

  context "First user" do
    it "should be created this admin access via db:seed" do
      require 'rake'
      Errbit::Application.load_tasks
      Rake::Task["db:seed"].execute
      User.first.admin.should be_true
    end
  end

end

