require 'spec_helper'

describe App do
  context "Attributes" do
    it { should have_field(:_id).of_type(String) }
    it { should have_field(:name).of_type(String) }
    it { should have_fields(:api_key, :github_repo, :bitbucket_repo, :asset_host, :repository_branch) }
    it { should have_fields(:resolve_errs_on_deploy, :notify_all_users, :notify_on_errs, :notify_on_deploys).of_type(Boolean) }
    it { should have_field(:email_at_notices).of_type(Array).with_default_value_of(Errbit::Config.email_at_notices) }
  end

  context 'validations' do
    it 'requires a name' do
      app = Fabricate.build(:app, :name => nil)
      expect(app).to_not be_valid
      expect(app.errors[:name]).to include("can't be blank")
    end

    it 'requires unique names' do
      Fabricate(:app, :name => 'Errbit')
      app = Fabricate.build(:app, :name => 'Errbit')
      expect(app).to_not be_valid
      expect(app.errors[:name]).to include('is already taken')
    end

    it 'requires unique api_keys' do
      Fabricate(:app, :api_key => 'APIKEY')
      app = Fabricate.build(:app, :api_key => 'APIKEY')
      expect(app).to_not be_valid
      expect(app.errors[:api_key]).to include('is already taken')
    end
  end

  describe '<=>' do
    it 'is compared by unresolved count' do
      app_0 = stub_model(App, :name => 'app', :unresolved_count => 1, :problem_count => 1)
      app_1 = stub_model(App, :name => 'app', :unresolved_count => 0, :problem_count => 1)

      expect(app_0).to be < app_1
      expect(app_1).to be > app_0
    end

    it 'is compared by problem count' do
      app_0 = stub_model(App, :name => 'app', :unresolved_count => 0, :problem_count => 1)
      app_1 = stub_model(App, :name => 'app', :unresolved_count => 0, :problem_count => 0)

      expect(app_0).to be < app_1
      expect(app_1).to be > app_0
    end

    it 'is compared by name' do
      app_0 = stub_model(App, :name => 'app_0', :unresolved_count => 0, :problem_count => 0)
      app_1 = stub_model(App, :name => 'app_1', :unresolved_count => 0, :problem_count => 0)

      expect(app_0).to be < app_1
      expect(app_1).to be > app_0
    end
  end

  context 'being created' do
    it 'generates a new api-key' do
      app = Fabricate.build(:app)
      expect(app.api_key).to be_nil
      app.save
      expect(app.api_key).to_not be_nil
    end

    it 'generates a correct api-key' do
      app = Fabricate(:app)
      expect(app.api_key).to match(/^[a-f0-9]{32}$/)
    end

    it 'is fine with blank github repos' do
      app = Fabricate.build(:app, :github_repo => "")
      app.save
      expect(app.github_repo).to eq ""
    end

    it 'doesnt touch github user/repo' do
      app = Fabricate.build(:app, :github_repo => "errbit/errbit")
      app.save
      expect(app.github_repo).to eq "errbit/errbit"
    end

    it 'removes domain from https github repos' do
      app = Fabricate.build(:app, :github_repo => "https://github.com/errbit/errbit")
      app.save
      expect(app.github_repo).to eq "errbit/errbit"
    end

    it 'normalizes public git repo as a github repo' do
      app = Fabricate.build(:app, :github_repo => "https://github.com/errbit/errbit.git")
      app.save
      expect(app.github_repo).to eq "errbit/errbit"
    end

    it 'normalizes private git repo as a github repo' do
      app = Fabricate.build(:app, :github_repo => "git@github.com:errbit/errbit.git")
      app.save
      expect(app.github_repo).to eq "errbit/errbit"
    end
  end

  context '#github_url_to_file' do
    it 'resolves to full path to file' do
      app = Fabricate(:app, :github_repo => "errbit/errbit")
      expect(app.github_url_to_file('path/to/file')).to eq "https://github.com/errbit/errbit/blob/master/path/to/file"
    end
  end

  context '#github_repo?' do
    it 'is true when there is a github_repo' do
      app = Fabricate(:app, :github_repo => "errbit/errbit")
      expect(app.github_repo?).to be_true
    end

    it 'is false when no github_repo' do
      app = Fabricate(:app)
      expect(app.github_repo?).to be_false
    end
  end

  context "notification recipients" do
    it "should send notices to either all users plus watchers, or the configured watchers" do
      @app = Fabricate(:app)
      3.times { Fabricate(:user) }
      5.times { Fabricate(:watcher, :app => @app) }
      @app.notify_all_users = true
      expect(@app.notification_recipients.size).to eq 8
      @app.notify_all_users = false
      expect(@app.notification_recipients.size).to eq 5
    end
  end

  context "emailable?" do
    it "should be true if notify on errs and there are notification recipients" do
      app = Fabricate(:app, :notify_on_errs => true, :notify_all_users => false)
      2.times { Fabricate(:watcher, :app => app) }
      expect(app.emailable?).to be_true
    end

    it "should be false if notify on errs is disabled" do
      app = Fabricate(:app, :notify_on_errs => false, :notify_all_users => false)
      2.times { Fabricate(:watcher, :app => app) }
      expect(app.emailable?).to be_false
    end

    it "should be false if there are no notification recipients" do
      app = Fabricate(:app, :notify_on_errs => true, :notify_all_users => false)
      expect(app.watchers).to be_empty
      expect(app.emailable?).to be_false
    end
  end

  context "copying attributes from existing app" do
    it "should only copy the necessary fields" do
      @app, @copy_app = Fabricate(:app, :name => "app", :github_repo => "url"),
                        Fabricate(:app, :name => "copy_app", :github_repo => "copy url")
      @copy_watcher = Fabricate(:watcher, :email => "copywatcher@example.com", :app => @copy_app)
      @app.copy_attributes_from(@copy_app.id)
      expect(@app.name).to eq "app"
      expect(@app.github_repo).to eq "copy url"
      expect(@app.watchers.first.email).to eq "copywatcher@example.com"
    end
  end

  context '#find_or_create_err!' do
    let(:app) { Fabricate(:app) }
    let(:conditions) { {
        :error_class  => 'Whoops',
        :environment  => 'production',
        :fingerprint  => 'some-finger-print'
      }
    }

    it 'returns the correct err if one already exists' do
      existing = Fabricate(:err, {
        :problem => Fabricate(:problem, :app => app),
        :fingerprint => conditions[:fingerprint]
      })
      expect(Err.where(:fingerprint => conditions[:fingerprint]).first).to eq existing
      expect(app.find_or_create_err!(conditions)).to eq existing
    end

    it 'assigns the returned err to the given app' do
      expect(app.find_or_create_err!(conditions).app).to eq app
    end

    it 'creates a new problem if a matching one does not already exist' do
      expect(Err.where(conditions).first).to be_nil
      expect {
        app.find_or_create_err!(conditions)
      }.to change(Problem,:count).by(1)
    end

    context "without error_class" do
      let(:conditions) { {
        :environment  => 'production',
        :fingerprint  => 'some-finger-print'
      }
      }
      it 'save the err' do
        expect(Err.where(conditions).first).to be_nil
        expect {
          app.find_or_create_err!(conditions)
        }.to change(Problem,:count).by(1)
      end
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

