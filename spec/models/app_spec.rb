# frozen_string_literal: true

require "rails_helper"

RSpec.describe App, type: :model do
  context "Attributes" do
    it { is_expected.to have_field(:_id).of_type(String) }

    it { is_expected.to have_field(:name).of_type(String) }

    it { is_expected.to have_fields(:api_key, :github_repo, :bitbucket_repo, :asset_host, :repository_branch) }

    it { is_expected.to have_fields(:notify_all_users, :notify_on_errs).of_type(Mongoid::Boolean) }

    it { is_expected.to have_field(:email_at_notices).of_type(Array).with_default_value_of(Config.errbit.email_at_notices) }
  end

  context "validations" do
    it "requires a name" do
      app = build(:app, name: nil)

      expect(app.valid?).to eq(false)

      expect(app.errors[:name]).to include("can't be blank")
    end

    it "requires unique names" do
      create(:app, name: "Errbit")

      app = build(:app, name: "Errbit")

      expect(app.valid?).to eq(false)

      expect(app.errors[:name]).to eq(["has already been taken"])
    end

    it "requires unique api_keys" do
      create(:app, api_key: "APIKEY")
      app = build(:app, api_key: "APIKEY")
      expect(app.valid?).to eq(false)
      expect(app.errors[:api_key]).to eq(["has already been taken"])
    end
  end

  describe "<=>" do
    it "is compared by unresolved count" do
      app_0 = stub_model(App, name: "app", unresolved_count: 1, problem_count: 1)
      app_1 = stub_model(App, name: "app", unresolved_count: 0, problem_count: 1)

      expect(app_0).to be < app_1
      expect(app_1).to be > app_0
    end

    it "is compared by problem count" do
      app_0 = stub_model(App, name: "app", unresolved_count: 0, problem_count: 1)
      app_1 = stub_model(App, name: "app", unresolved_count: 0, problem_count: 0)

      expect(app_0).to be < app_1
      expect(app_1).to be > app_0
    end

    it "is compared by name" do
      app_0 = stub_model(App, name: "app_0", unresolved_count: 0, problem_count: 0)
      app_1 = stub_model(App, name: "app_1", unresolved_count: 0, problem_count: 0)

      expect(app_0).to be < app_1
      expect(app_1).to be > app_0
    end
  end

  context "being created" do
    it "generates a new api-key" do
      app = build(:app)

      expect(app.api_key).to eq(nil)

      app.save

      expect(app.api_key).not_to eq(nil)
    end

    it "generates a correct api-key" do
      app = create(:app)

      expect(app.api_key).to match(/^[a-f0-9]{32}$/)
    end

    it "is fine with blank github repos" do
      app = build(:app, github_repo: "")

      app.save

      expect(app.github_repo).to eq("")
    end

    it "doesnt touch github user/repo" do
      app = build(:app, github_repo: "errbit/errbit")

      app.save

      expect(app.github_repo).to eq("errbit/errbit")
    end

    it "removes domain from https github repos" do
      app = build(:app, github_repo: "https://github.com/errbit/errbit")

      app.save

      expect(app.github_repo).to eq("errbit/errbit")
    end

    it "normalizes public git repo as a github repo" do
      app = build(:app, github_repo: "https://github.com/errbit/errbit.git")

      app.save

      expect(app.github_repo).to eq("errbit/errbit")
    end

    it "normalizes private git repo as a github repo" do
      app = build(:app, github_repo: "git@github.com:errbit/errbit.git")

      app.save

      expect(app.github_repo).to eq("errbit/errbit")
    end
  end

  describe "#github_url_to_file" do
    it "resolves to full path to file" do
      app = create(:app, github_repo: "errbit/errbit", repository_branch: "main")

      expect(app.github_url_to_file("path/to/file")).to eq("https://github.com/errbit/errbit/blob/main/path/to/file")
    end
  end

  describe "#github_repo?" do
    it "is true when there is a github_repo" do
      app = create(:app, github_repo: "errbit/errbit")

      expect(app.github_repo?).to eq(true)
    end

    it "is false when no github_repo" do
      app = create(:app)

      expect(app.github_repo?).to eq(false)
    end
  end

  context "notification recipients" do
    it "should send notices to either all users plus watchers, or the configured watchers" do
      app = create(:app)
      create_list(:user, 3)
      create_list(:watcher, 5, app: app)
      app.notify_all_users = true
      expect(app.notification_recipients.size).to eq(8)
      app.notify_all_users = false
      expect(app.notification_recipients.size).to eq(5)
    end
  end

  describe "#emailable?" do
    it "should be true if notify on errs and there are notification recipients" do
      app = create(:app, notify_on_errs: true, notify_all_users: false)

      create_list(:watcher, 2, app: app)

      expect(app.emailable?).to eq(true)
    end

    it "should be false if notify on errs is disabled" do
      app = create(:app, notify_on_errs: false, notify_all_users: false)
      create_list(:watcher, 2, app: app)
      expect(app.emailable?).to eq(false)
    end

    it "should be false if there are no notification recipients" do
      app = create(:app, notify_on_errs: true, notify_all_users: false)
      expect(app.watchers).to be_empty
      expect(app.emailable?).to eq(false)
    end
  end

  context "copying attributes from existing app" do
    it "should only copy the necessary fields" do
      app = create(:app, name: "app", github_repo: "url")
      copy_app = create(:app, name: "copy_app", github_repo: "copy url")
      create(:watcher, email: "copywatcher@example.com", app: copy_app)
      app.copy_attributes_from(copy_app.id)
      expect(app.name).to eq("app")
      expect(app.github_repo).to eq("copy url")
      expect(app.watchers.first.email).to eq("copywatcher@example.com")
    end
  end

  describe "#find_or_create_err!" do
    let(:app) { create(:app) }

    let(:conditions) do
      {
        error_class: "Whoops",
        environment: "production",
        fingerprint: "some-finger-print"
      }
    end

    it "returns the correct err if one already exists" do
      problem = create(:problem, app: app)
      existing = create(:err,
        problem: problem,
        fingerprint: conditions[:fingerprint])
      expect(Err.where(fingerprint: conditions[:fingerprint]).first).to eq(existing)
      expect(app.find_or_create_err!(conditions)).to eq(existing)
    end

    it "assigns the returned err to the given app" do
      expect(app.find_or_create_err!(conditions).app).to eq(app)
    end

    it "creates a new problem if a matching one does not already exist" do
      expect(Err.where(conditions).first).to eq(nil)
      expect do
        app.find_or_create_err!(conditions)
      end.to change(Problem, :count).by(1)
    end

    context "without error_class" do
      let(:conditions) do
        {
          environment: "production",
          fingerprint: "some-finger-print"
        }
      end

      it "save the err" do
        expect(Err.where(conditions).first).to eq(nil)
        expect do
          app.find_or_create_err!(conditions)
        end.to change(Problem, :count).by(1)
      end
    end
  end

  describe ".find_by_api_key!" do
    it "return the app with api_key" do
      app = create(:app)
      expect(App.find_by_api_key!(app.api_key)).to eq(app)
    end

    it "raise Mongoid::Errors::DocumentNotFound if not found" do
      expect do
        App.find_by_api_key!("foo")
      end.to raise_error(Mongoid::Errors::DocumentNotFound)
    end
  end

  describe "#notice_fingerprinter" do
    it "app acquires a notice_fingerprinter when it doesn't have one" do
      app = create(:app, name: "Errbit")

      app.notice_fingerprinter.delete

      # has a notice_fingerprinter because it's been accessed when blank
      expect(app.reload.notice_fingerprinter).to be_a(NoticeFingerprinter)
    end

    it "brand new app has a notice_fingerprinter" do
      app = create(:app, name: "Errbit")

      expect(app.notice_fingerprinter).to be_a(NoticeFingerprinter)
    end
  end

  context "searching" do
    it "finds the correct record" do
      found = create(:app, name: "Foo")

      create(:app, name: "Brr")

      expect(App.search("Foo").to_a).to eq([found])
    end
  end

  describe "#attributes_for_super_diff" do
    subject { create(:app) }

    it { expect(subject.attributes_for_super_diff).to eq(id: subject.id.to_s, name: subject.name) }
  end
end
