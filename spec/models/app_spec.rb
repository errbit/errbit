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


  context '#report_error!' do
    before do
      @xml = Rails.root.join('spec','fixtures','hoptoad_test_notice.xml').read
      @app = Fabricate(:app, :api_key => 'APIKEY')
      ErrorReport.any_instance.stub(:fingerprint).and_return('fingerprintdigest')
    end

    it 'finds the correct app' do
      @notice = App.report_error!(@xml)
      @notice.err.app.should == @app
    end

    it 'finds the correct err for the notice' do
      App.should_receive(:find_by_api_key!).and_return(@app)
      @app.should_receive(:find_or_create_err!).with({
        :error_class  => 'HoptoadTestingException',
        :component    => 'application',
        :action       => 'verify',
        :environment  => 'development',
        :fingerprint  => 'fingerprintdigest'
      }).and_return(err = Fabricate(:err))
      err.notices.stub(:create!)
      @notice = App.report_error!(@xml)
    end

    it 'marks the err as unresolved if it was previously resolved' do
      App.should_receive(:find_by_api_key!).and_return(@app)
      @app.should_receive(:find_or_create_err!).with({
        :error_class  => 'HoptoadTestingException',
        :component    => 'application',
        :action       => 'verify',
        :environment  => 'development',
        :fingerprint  => 'fingerprintdigest'
      }).and_return(err = Fabricate(:err, :problem => Fabricate(:problem, :resolved => true)))
      err.should be_resolved
      @notice = App.report_error!(@xml)
      @notice.err.should == err
      @notice.err.should_not be_resolved
    end

    it 'should create a new notice' do
      @notice = App.report_error!(@xml)
      @notice.should be_persisted
    end

    it 'assigns an err to the notice' do
      @notice = App.report_error!(@xml)
      @notice.err.should be_a(Err)
    end

    it 'captures the err message' do
      @notice = App.report_error!(@xml)
      @notice.message.should == 'HoptoadTestingException: Testing hoptoad via "rake hoptoad:test". If you can see this, it works.'
    end

    it 'captures the backtrace' do
      @notice = App.report_error!(@xml)
      @notice.backtrace_lines.size.should == 73
      @notice.backtrace_lines.last['file'].should == '[GEM_ROOT]/bin/rake'
    end

    it 'captures the server_environment' do
      @notice = App.report_error!(@xml)
      @notice.server_environment['environment-name'].should == 'development'
    end

    it 'captures the request' do
      @notice = App.report_error!(@xml)
      @notice.request['url'].should == 'http://example.org/verify'
      @notice.request['params']['controller'].should == 'application'
    end

    it 'captures the notifier' do
      @notice = App.report_error!(@xml)
      @notice.notifier['name'].should == 'Hoptoad Notifier'
    end

    it "should handle params without 'request' section" do
      xml = Rails.root.join('spec','fixtures','hoptoad_test_notice_without_request_section.xml').read
      lambda { App.report_error!(xml) }.should_not raise_error
    end

    it "should handle params with only a single line of backtrace" do
      xml = Rails.root.join('spec','fixtures','hoptoad_test_notice_with_one_line_of_backtrace.xml').read
      lambda { @notice = App.report_error!(xml) }.should_not raise_error
      @notice.backtrace_lines.length.should == 1
    end

    it 'captures the current_user' do
      @notice = App.report_error!(@xml)
      @notice.current_user['id'].should == '123'
      @notice.current_user['name'].should == 'Mr. Bean'
      @notice.current_user['email'].should == 'mr.bean@example.com'
      @notice.current_user['username'].should == 'mrbean'
    end

    it 'captures the framework' do
      @notice = App.report_error!(@xml)
      @notice.framework.should == 'Rails: 3.2.11'
    end

  end


end

