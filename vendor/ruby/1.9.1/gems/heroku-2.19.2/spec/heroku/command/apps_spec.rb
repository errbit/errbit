require "spec_helper"
require "heroku/command/apps"

module Heroku::Command
  describe Apps do
    before(:each) do
      @cli = prepare_command(Apps)
      @cli.stub(:options).and_return(:app => "myapp")
      @data = {
        :addons         => [],
        :collaborators  => [],
        :database_size  => 5*1024*1024,
        :git_url        => 'git@heroku.com/myapp.git',
        :name           => 'myapp',
        :repo_size      => 2*1024,
        :web_url        => 'http://myapp.heroku.com/'
      }
    end

    it "shows app info, converting bytes to kbs/mbs" do
      @cli.heroku.should_receive(:info).with('myapp').and_return(@data)
      @cli.should_receive(:hputs).with('=== myapp')
      @cli.should_receive(:hputs).with('Database Size: 5M')
      @cli.should_receive(:hputs).with('Git URL:       git@heroku.com/myapp.git')
      @cli.should_receive(:hputs).with('Repo Size:     2k')
      @cli.should_receive(:hputs).with('Web URL:       http://myapp.heroku.com/')
      @cli.info
    end

    it "shows app info using the --app syntax" do
      @cli.stub!(:options).and_return(:app => "myapp")
      @cli.heroku.should_receive(:info).and_return(@data)
      @cli.info
    end

    it "shows app info reading app from current git dir" do
      @cli.stub!(:options).and_return({})
      @cli.stub!(:extract_app_in_dir).and_return('myapp')
      @cli.heroku.should_receive(:info).with('myapp').and_return(@data)
      @cli.info
    end

    it "shows raw app info when --raw option is used" do
      @cli.stub(:options).and_return(:app => "myapp", :raw => true)
      @cli.heroku.should_receive(:info).with("myapp").and_return({ :foo => "bar" })
      @cli.should_receive(:hputs).with("foo=bar")
      @cli.info
    end

    it "creates without a name" do
      @cli.heroku.should_receive(:create_request).with(nil, {:stack => nil}).and_return("untitled-123")
      @cli.heroku.should_receive(:create_complete?).with("untitled-123").and_return(true)
      @cli.heroku.stub!(:info).and_return({:git_url => 'git@heroku.com:untitled-123.git'})
      @cli.should_receive(:create_git_remote).with('heroku', 'git@heroku.com:untitled-123.git')
      @cli.create
    end

    it "creates with a name" do
      @cli.stub!(:args).and_return(["myapp"])
      @cli.heroku.should_receive(:create_request).with('myapp', {:stack => nil}).and_return("myapp")
      @cli.heroku.should_receive(:create_complete?).with("myapp").and_return(true)
      @cli.heroku.stub!(:info).and_return({:git_url => 'git@heroku.com:myapp.git'})
      @cli.should_receive(:create_git_remote).with('heroku', 'git@heroku.com:myapp.git')
      @cli.create
    end

    it "creates with addons" do
      @cli.stub!(:args).and_return(["addonapp"])
      @cli.stub!(:options).and_return(:addons => "foo:bar,fred:barney")
      @cli.heroku.should_receive(:create_request).with('addonapp', {:stack => nil}).and_return("addonapp")
      @cli.heroku.should_receive(:create_complete?).with("addonapp").and_return(true)
      @cli.heroku.should_receive(:install_addon).with("addonapp", "foo:bar")
      @cli.heroku.should_receive(:install_addon).with("addonapp", "fred:barney")
      @cli.heroku.stub!(:info).and_return({:git_url => 'git@heroku.com:addonapp.git'})
      @cli.should_receive(:create_git_remote).with('heroku', 'git@heroku.com:addonapp.git')
      @cli.create
    end

    it "creates with a buildpack" do
      @cli.stub!(:args).and_return(["buildpackapp"])
      @cli.stub!(:options).and_return(:buildpack => "http://example.org/buildpack.git")
      @cli.heroku.should_receive(:create_request).with('buildpackapp', {:stack => nil}).and_return("buildpackapp")
      @cli.heroku.should_receive(:create_complete?).with("buildpackapp").and_return(true)
      @cli.heroku.should_receive(:add_config_vars).with("buildpackapp", "BUILDPACK_URL" => "http://example.org/buildpack.git")
      @cli.heroku.stub!(:info).and_return({:git_url => 'git@heroku.com:buildpackapp.git'})
      @cli.should_receive(:create_git_remote).with('heroku', 'git@heroku.com:buildpackapp.git')
      @cli.create
    end

    it "creates with an alternate remote name" do
      @cli.stub!(:options).and_return(:remote => "alternate")
      @cli.stub!(:args).and_return([ 'alternate-remote' ])
      @cli.heroku.should_receive(:create_request).and_return("alternate-remote")
      @cli.heroku.should_receive(:create_complete?).with("alternate-remote").and_return(true)
      @cli.heroku.stub!(:info).and_return({:git_url => 'git@heroku.com:alternate-remote.git'})
      @cli.should_receive(:create_git_remote).with('alternate', 'git@heroku.com:alternate-remote.git')
      @cli.create
    end

    it "renames an app" do
      @cli.stub!(:args).and_return([ 'myapp2' ])
      @cli.heroku.should_receive(:update).with('myapp', { :name => 'myapp2' })
      @cli.heroku.stub!(:info).and_return({:git_url => 'git@heroku.com:myapp2.git'})
      @cli.rename
    end

    it "displays an error if no name is specified on rename" do
      Heroku::Command.should_receive(:error).with(/Must specify a new name/)
      run "rename --app bar"
    end

    it "destroys the app specified with --app if user confirms" do
      @cli.stub!(:options).and_return(:app => "myapp")
      @cli.should_receive(:confirm_command).and_return(true)
      @cli.heroku.stub!(:info).and_return({:git_url => 'git@heroku.com:myapp.git'})
      @cli.heroku.should_receive(:destroy).with('myapp')
      @cli.destroy
    end

    it "doesn't destroy the app if the user doesn't confirms" do
      @cli.stub!(:options).and_return(:app => "myapp")
      @cli.should_receive(:confirm_command).and_return(false)
      @cli.heroku.stub!(:info).and_return({:git_url => 'git@heroku.com:myapp.git'})
      @cli.heroku.should_not_receive(:destroy)
      @cli.destroy
    end

    it "doesn't destroy the app in the current dir" do
      @cli.stub!(:app).and_return('myapp')
      @cli.heroku.stub!(:info).and_return({:git_url => 'git@heroku.com:myapp.git'})
      @cli.heroku.should_not_receive(:destroy)
      @cli.destroy
    end

    context "Git Integration" do
      include SandboxHelper
      before(:all) do
        # setup a git dir to serve as a remote
        @git = "/tmp/git_spec_#{Process.pid}"
        FileUtils.mkdir_p(@git)
        FileUtils.cd(@git) { |d| `git --bare init` }
      end

      after(:all) do
        FileUtils.rm_rf(@git)
      end

      it "creates adding heroku to git remote" do
        with_blank_git_repository do
          @cli.heroku.should_receive(:create_request).and_return('myapp')
          @cli.heroku.should_receive(:create_complete?).with('myapp').and_return(true)
          @cli.heroku.stub!(:info).and_return({:git_url => 'git@heroku.com:myapp.git'})
          @cli.create
          bash("git remote").strip.should == 'heroku'
        end
      end

      it "creates adding a custom git remote" do
        with_blank_git_repository do
          @cli.stub!(:args).and_return([ 'myapp' ])
          @cli.stub!(:options).and_return(:remote => "myremote")
          @cli.heroku.should_receive(:create_request).and_return('myapp')
          @cli.heroku.should_receive(:create_complete?).with('myapp').and_return(true)
          @cli.heroku.stub!(:info).and_return({:git_url => 'git@heroku.com:myapp.git'})
          @cli.create
          bash("git remote").strip.should == 'myremote'
        end
      end

      it "doesn't add a git remote if it already exists" do
        with_blank_git_repository do
          @cli.heroku.should_receive(:create_request).and_return('myapp')
          @cli.heroku.should_receive(:create_complete?).with('myapp').and_return(true)
          @cli.heroku.stub!(:info).and_return({:git_url => 'git@heroku.com:myapp.git'})
          bash "git remote add heroku #{@git}"
          @cli.create
        end
      end

      it "renames updating the corresponding heroku git remote" do
        with_blank_git_repository do
          bash "git remote add github     git@github.com:test/test.git"
          bash "git remote add production git@heroku.com:myapp.git"
          bash "git remote add staging    git@heroku.com:myapp-staging.git"

          @cli.heroku.stub!(:update)
          @cli.stub!(:args).and_return([ 'myapp2' ])
          @cli.heroku.stub!(:info).and_return({:git_url => 'git@heroku.com:myapp2.git'})
          @cli.rename
          remotes = bash("git remote -v")
          remotes.should include('git@github.com:test/test.git')
          remotes.should include('git@heroku.com:myapp-staging.git')
          remotes.should include('git@heroku.com:myapp2.git')
          remotes.should_not include('git@heroku.com:myapp.git')
        end
      end

      it "destroys removing any remotes pointing to the app" do
        with_blank_git_repository do
          bash("git remote add heroku git@heroku.com:myapp.git")
          @cli.stub!(:args).and_return(['--app', 'myapp'])
          @cli.stub!(:confirm_command).and_return(true)
          @cli.heroku.stub!(:info).and_return({:git_url => 'git@heroku.com:myapp.git'})
          @cli.heroku.should_receive(:destroy)
          @cli.destroy
          bash("git remote").strip.should == ''
        end
      end
    end
  end
end
