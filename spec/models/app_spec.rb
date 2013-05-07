require 'spec_helper'

describe App do
  context 'validations' do
    it 'requires a name' do
      app = Fabricate.build(:app, :name => nil)
      app.should_not be_valid
      app.errors[:name].should include("can't be blank")
    end

    it 'requires unique names' do
      Fabricate(:app, :name => 'Errbit')
      app = Fabricate.build(:app, :name => 'Errbit')
      app.should_not be_valid
      app.errors[:name].should include('is already taken')
    end

    it 'requires unique api_keys' do
      Fabricate(:app, :api_key => 'APIKEY')
      app = Fabricate.build(:app, :api_key => 'APIKEY')
      app.should_not be_valid
      app.errors[:api_key].should include('is already taken')
    end
  end

  describe '<=>' do
    it 'is compared by unresolved count' do
      app_0 = stub_model(App, :name => 'app', :unresolved_count => 1, :problem_count => 1)
      app_1 = stub_model(App, :name => 'app', :unresolved_count => 0, :problem_count => 1)

      app_0.should < app_1
      app_1.should > app_0
    end

    it 'is compared by problem count' do
      app_0 = stub_model(App, :name => 'app', :unresolved_count => 0, :problem_count => 1)
      app_1 = stub_model(App, :name => 'app', :unresolved_count => 0, :problem_count => 0)

      app_0.should < app_1
      app_1.should > app_0
    end

    it 'is compared by name' do
      app_0 = stub_model(App, :name => 'app_0', :unresolved_count => 0, :problem_count => 0)
      app_1 = stub_model(App, :name => 'app_1', :unresolved_count => 0, :problem_count => 0)

      app_0.should < app_1
      app_1.should > app_0
    end
  end

  context 'being created' do
    it 'generates a new api-key' do
      app = Fabricate.build(:app)
      app.api_key.should be_nil
      app.save
      app.api_key.should_not be_nil
    end

    it 'generates a correct api-key' do
      app = Fabricate(:app)
      app.api_key.should match(/^[a-f0-9]{32}$/)
    end

    it 'is fine with blank github repos' do
      app = Fabricate.build(:app, :github_repo => "")
      app.save
      app.github_repo.should == ""
    end

    it 'doesnt touch github user/repo' do
      app = Fabricate.build(:app, :github_repo => "errbit/errbit")
      app.save
      app.github_repo.should == "errbit/errbit"
    end

    it 'removes domain from https github repos' do
      app = Fabricate.build(:app, :github_repo => "https://github.com/errbit/errbit")
      app.save
      app.github_repo.should == "errbit/errbit"
    end

    it 'normalizes public git repo as a github repo' do
      app = Fabricate.build(:app, :github_repo => "https://github.com/errbit/errbit.git")
      app.save
      app.github_repo.should == "errbit/errbit"
    end

    it 'normalizes private git repo as a github repo' do
      app = Fabricate.build(:app, :github_repo => "git@github.com:errbit/errbit.git")
      app.save
      app.github_repo.should == "errbit/errbit"
    end
  end

  context '#github_url_to_file' do
    it 'resolves to full path to file' do
      app = Fabricate(:app, :github_repo => "errbit/errbit")
      app.github_url_to_file('path/to/file').should == "https://github.com/errbit/errbit/blob/master/path/to/file"
    end
  end

  context '#github_repo?' do
    it 'is true when there is a github_repo' do
      app = Fabricate(:app, :github_repo => "errbit/errbit")
      app.github_repo?.should be_true
    end

    it 'is false when no github_repo' do
      app = Fabricate(:app)
      app.github_repo?.should be_false
    end
  end

  context "notification recipients" do
    it "should send notices to either all users plus watchers, or the configured watchers" do
      @app = Fabricate(:app)
      3.times { Fabricate(:user) }
      5.times { Fabricate(:watcher, :app => @app) }
      @app.notify_all_users = true
      @app.notification_recipients.size.should == 8
      @app.notify_all_users = false
      @app.notification_recipients.size.should == 5
    end
  end

  context "emailable?" do
    it "should be true if notify on errs and there are notification recipients" do
      app = Fabricate(:app, :notify_on_errs => true, :notify_all_users => false)
      2.times { Fabricate(:watcher, :app => app) }
      app.emailable?.should be_true
    end

    it "should be false if notify on errs is disabled" do
      app = Fabricate(:app, :notify_on_errs => false, :notify_all_users => false)
      2.times { Fabricate(:watcher, :app => app) }
      app.emailable?.should be_false
    end

    it "should be false if there are no notification recipients" do
      app = Fabricate(:app, :notify_on_errs => true, :notify_all_users => false)
      app.watchers.should be_empty
      app.emailable?.should be_false
    end
  end

  context "copying attributes from existing app" do
    it "should only copy the necessary fields" do
      @app, @copy_app = Fabricate(:app, :name => "app", :github_repo => "url"),
                        Fabricate(:app, :name => "copy_app", :github_repo => "copy url")
      @copy_watcher = Fabricate(:watcher, :email => "copywatcher@example.com", :app => @copy_app)
      @app.copy_attributes_from(@copy_app.id)
      @app.name.should == "app"
      @app.github_repo.should == "copy url"
      @app.watchers.first.email.should == "copywatcher@example.com"
    end
  end


  context '#find_or_create_err!' do
    before do
      @app = Fabricate(:app)
      @conditions = {
        :error_class  => 'Whoops',
        :component    => 'Foo',
        :action       => 'bar',
        :environment  => 'production'
      }
    end

    it 'returns the correct err if one already exists' do
      existing = Fabricate(:err, @conditions.merge(:problem => Fabricate(:problem, :app => @app)))
      Err.where(@conditions).first.should == existing
      @app.find_or_create_err!(@conditions).should == existing
    end

    it 'assigns the returned err to the given app' do
      @app.find_or_create_err!(@conditions).app.should == @app
    end

    it 'creates a new problem if a matching one does not already exist' do
      Err.where(@conditions).first.should be_nil
      lambda {
        @app.find_or_create_err!(@conditions)
      }.should change(Problem,:count).by(1)
    end
  end


  describe ".find_by_api_key!" do
    it 'return the app with api_key' do
      app = Fabricate(:app)
      expect(App.find_by_api_key!(app.api_key)).to eq app
    end
    it 'raise Mongoid::Errors::DocumentNotFound if not found' do
      expect {
        App.find_by_api_key!('foo')
      }.to raise_error(Mongoid::Errors::DocumentNotFound)
    end
  end

end

