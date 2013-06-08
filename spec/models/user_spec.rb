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

    it 'requires uniq github login' do
      user1 = Fabricate(:user, :github_login => 'nashby')
      user1.should be_valid

      user2 = Fabricate.build(:user, :github_login => 'nashby')
      user2.save
      user2.should_not be_valid
      user2.errors[:github_login].should include("is already taken")
    end

    it 'allows blank / null github_login' do
      user1 = Fabricate(:user, :github_login => ' ')
      user1.should be_valid

      user2 = Fabricate.build(:user, :github_login => ' ')
      user2.save
      user2.should be_valid
    end
  end

  context 'Watchers' do

    it 'has many watchers' do
      user = Fabricate(:user)
      watcher = Fabricate(:user_watcher, :user => user)
      user.watchers.should_not be_empty
      user.watchers.should include(watcher)
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
      expect {
        $stdout.stub(:puts => true)
        require Rails.root.join('db/seeds.rb')
      }.to change {
        User.where(:admin => true).count
      }.from(0).to(1)
    end
  end

end

