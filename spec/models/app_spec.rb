require 'spec_helper'

describe App do

  context 'validations' do
    it 'requires a name' do
      app = Factory.build(:app, :name => nil)
      app.should_not be_valid
      app.errors[:name].should include("can't be blank")
    end

    it 'requires unique names' do
      Factory(:app, :name => 'Errbit')
      app = Factory.build(:app, :name => 'Errbit')
      app.should_not be_valid
      app.errors[:name].should include('is already taken')
    end

    it 'requires unique api_keys' do
      Factory(:app, :api_key => 'APIKEY')
      app = Factory.build(:app, :api_key => 'APIKEY')
      app.should_not be_valid
      app.errors[:api_key].should include('is already taken')
    end
  end

  context 'being created' do
    it 'generates a new api-key' do
      app = Factory.build(:app)
      app.api_key.should be_nil
      app.save
      app.api_key.should_not be_nil
    end

    it 'generates a correct api-key' do
      app = Factory(:app)
      app.api_key.should match(/^[a-f0-9]{32}$/)
    end

    it 'is fine with blank github urls' do
      app = Factory.build(:app, :github_url => "")
      app.save
      app.github_url.should == ""
    end

    it 'does not touch https github urls' do
      app = Factory.build(:app, :github_url => "https://github.com/errbit/errbit")
      app.save
      app.github_url.should == "https://github.com/errbit/errbit"
    end

    it 'normalizes http github urls' do
      app = Factory.build(:app, :github_url => "http://github.com/errbit/errbit")
      app.save
      app.github_url.should == "https://github.com/errbit/errbit"
    end

    it 'normalizes public git repo as a github url' do
      app = Factory.build(:app, :github_url => "https://github.com/errbit/errbit.git")
      app.save
      app.github_url.should == "https://github.com/errbit/errbit"
    end

    it 'normalizes private git repo as a github url' do
      app = Factory.build(:app, :github_url => "git@github.com:errbit/errbit.git")
      app.save
      app.github_url.should == "https://github.com/errbit/errbit"
    end
  end

  context '#github_url_to_file' do
    it 'resolves to full path to file' do
      app = Factory(:app, :github_url => "https://github.com/errbit/errbit")
      app.github_url_to_file('/path/to/file').should == "https://github.com/errbit/errbit/blob/master/path/to/file"
    end
  end

  context '#github_url?' do
    it 'is true when there is a github_url' do
      app = Factory(:app, :github_url => "https://github.com/errbit/errbit")
      app.github_url?.should be_true
    end

    it 'is false when no github_url' do
      app = Factory(:app)
      app.github_url?.should be_false
    end
  end

  context "notification recipients" do
    it "should send notices to either all users, or the configured watchers" do
      @app = Factory(:app)
      3.times { Factory(:user) }
      5.times { Factory(:watcher, :app => @app) }
      @app.notify_all_users = true
      @app.notification_recipients.size.should == 3
      @app.notify_all_users = false
      @app.notification_recipients.size.should == 5
    end
  end

  context "copying attributes from existing app" do
    it "should only copy the necessary fields" do
      @app, @copy_app = Factory(:app, :name => "app", :github_url => "url"),
                        Factory(:app, :name => "copy_app", :github_url => "copy url")
      @copy_watcher = Factory(:watcher, :email => "copywatcher@example.com", :app => @copy_app)
      @app.copy_attributes_from(@copy_app.id)
      @app.name.should == "app"
      @app.github_url.should == "copy url"
      @app.watchers.first.email.should == "copywatcher@example.com"
    end
  end
end

