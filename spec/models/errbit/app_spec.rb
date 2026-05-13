# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::App, type: :model do
  it "inherits from Errbit::ApplicationRecord" do
    expect(described_class.ancestors).to include(Errbit::ApplicationRecord)
  end

  it "uses the errbit_apps table" do
    expect(described_class.table_name).to eq("errbit_apps")
  end

  context "validations" do
    it "requires a name" do
      app = build(:errbit_app, name: nil)

      expect(app.valid?).to eq(false)
      expect(app.errors[:name]).to include("can't be blank")
    end

    it "requires unique names" do
      create(:errbit_app, name: "Errbit")
      app = build(:errbit_app, name: "Errbit")

      expect(app.valid?).to eq(false)
      expect(app.errors[:name]).to eq(["has already been taken"])
    end

    it "requires unique api_keys" do
      create(:errbit_app, api_key: "APIKEY")
      app = build(:errbit_app, api_key: "APIKEY")

      expect(app.valid?).to eq(false)
      expect(app.errors[:api_key]).to eq(["has already been taken"])
    end
  end

  context "being created" do
    it "generates a new api-key" do
      app = build(:errbit_app)

      expect(app.api_key).to eq(nil)

      app.save

      expect(app.api_key).not_to eq(nil)
    end

    it "generates a correct api-key" do
      app = create(:errbit_app)

      expect(app.api_key).to match(/^[a-f0-9]{32}$/)
    end

    it "is fine with blank github repos" do
      app = build(:errbit_app, github_repo: "")
      app.save

      expect(app.github_repo).to eq("")
    end

    it "doesn't touch a plain github user/repo" do
      app = build(:errbit_app, github_repo: "errbit/errbit")
      app.save

      expect(app.github_repo).to eq("errbit/errbit")
    end

    it "removes domain from https github repos" do
      app = build(:errbit_app, github_repo: "https://github.com/errbit/errbit")
      app.save

      expect(app.github_repo).to eq("errbit/errbit")
    end

    it "normalizes public git repo as a github repo" do
      app = build(:errbit_app, github_repo: "https://github.com/errbit/errbit.git")
      app.save

      expect(app.github_repo).to eq("errbit/errbit")
    end

    it "normalizes private git repo as a github repo" do
      app = build(:errbit_app, github_repo: "git@github.com:errbit/errbit.git")
      app.save

      expect(app.github_repo).to eq("errbit/errbit")
    end
  end

  describe "#repo_branch" do
    it "falls back to main when blank" do
      app = build(:errbit_app)

      expect(app.repo_branch).to eq("main")
    end

    it "returns the stored branch when present" do
      app = build(:errbit_app, repository_branch: "develop")

      expect(app.repo_branch).to eq("develop")
    end
  end

  describe "#github_repo?" do
    it "is true when there is a github_repo" do
      app = create(:errbit_app, github_repo: "errbit/errbit")

      expect(app.github_repo?).to eq(true)
    end

    it "is false when no github_repo" do
      app = create(:errbit_app)

      expect(app.github_repo?).to eq(false)
    end
  end

  describe "#github_url" do
    it "returns nil when no repo" do
      expect(build(:errbit_app).github_url).to be_nil
    end

    it "joins the configured base url with the repo" do
      app = build(:errbit_app, github_repo: "errbit/errbit")

      expect(app.github_url).to eq("https://github.com/errbit/errbit")
    end
  end

  describe "#github_url_to_file" do
    it "resolves to full path to file" do
      app = create(:errbit_app, github_repo: "errbit/errbit", repository_branch: "main")

      expect(app.github_url_to_file("path/to/file")).to eq("https://github.com/errbit/errbit/blob/main/path/to/file")
    end
  end

  describe "#bitbucket_repo?" do
    it "is true when bitbucket_repo is present" do
      app = build(:errbit_app, bitbucket_repo: "errbit/errbit")

      expect(app.bitbucket_repo?).to eq(true)
    end

    it "is false otherwise" do
      expect(build(:errbit_app).bitbucket_repo?).to eq(false)
    end
  end

  describe "#bitbucket_url_to_file" do
    it "resolves to full path to file" do
      app = create(:errbit_app, bitbucket_repo: "errbit/errbit", repository_branch: "main")

      expect(app.bitbucket_url_to_file("path/to/file")).to eq("https://bitbucket.org/errbit/errbit/src/main/path/to/file")
    end
  end

  describe "#notify_on_errs" do
    it "defaults to true" do
      app = build(:errbit_app)

      expect(app.notify_on_errs?).to eq(true)
    end

    it "is false when explicitly false" do
      app = build(:errbit_app, notify_on_errs: false)

      expect(app.notify_on_errs?).to eq(false)
    end
  end

  describe "#regenerate_api_key!" do
    it "replaces the api_key" do
      app = create(:errbit_app)
      original = app.api_key

      app.regenerate_api_key!

      expect(app.api_key).not_to eq(original)
      expect(app.api_key).to match(/^[a-f0-9]{32}$/)
    end
  end

  describe ".find_by_api_key!" do
    it "returns the app with the given api_key" do
      app = create(:errbit_app)

      expect(described_class.find_by_api_key!(app.api_key)).to eq(app)
    end

    it "raises when not found" do
      expect {
        described_class.find_by_api_key!("does-not-exist")
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe ".search" do
    it "finds the correct record" do
      found = create(:errbit_app, name: "Foo")
      create(:errbit_app, name: "Brr")

      expect(described_class.search("Foo").to_a).to eq([found])
    end
  end

  describe "#attributes_for_super_diff" do
    subject { create(:errbit_app) }

    it { expect(subject.attributes_for_super_diff).to eq(id: subject.id, name: subject.name) }
  end
end
