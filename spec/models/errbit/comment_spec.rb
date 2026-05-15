# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::Comment, type: :model do
  it "inherits from Errbit::ApplicationRecord" do
    expect(described_class.ancestors).to include(Errbit::ApplicationRecord)
  end

  it "uses the errbit_comments table" do
    expect(described_class.table_name).to eq("errbit_comments")
  end

  context "validations" do
    it "requires a body" do
      comment = build(:errbit_comment, body: nil)

      expect(comment.valid?).to eq(false)
      expect(comment.errors[:body]).to include("can't be blank")
    end

    it "requires an err (problem)" do
      comment = build(:errbit_comment, err: nil)

      expect(comment.valid?).to eq(false)
      expect(comment.errors[:err]).to include("must exist")
    end

    it "requires a user" do
      comment = build(:errbit_comment, user: nil)

      expect(comment.valid?).to eq(false)
      expect(comment.errors[:user]).to include("must exist")
    end
  end

  describe "delegation" do
    it "delegates app to err" do
      app = create(:errbit_app)
      problem = create(:errbit_problem, app: app)
      comment = create(:errbit_comment, err: problem)

      expect(comment.app).to eq(app)
    end
  end

  describe "counter cache" do
    it "increments comments_count on the problem when created" do
      problem = create(:errbit_problem)

      expect {
        create(:errbit_comment, err: problem)
      }.to change { problem.reload.comments_count }.from(0).to(1)
    end

    it "decrements comments_count on the problem when destroyed" do
      problem = create(:errbit_problem)
      comment = create(:errbit_comment, err: problem)

      expect {
        comment.destroy
      }.to change { problem.reload.comments_count }.from(1).to(0)
    end
  end

  describe ".ordered" do
    it "orders by created_at asc" do
      older = create(:errbit_comment, created_at: 2.days.ago)
      newer = create(:errbit_comment, created_at: 1.minute.ago)

      ordered = described_class.ordered.to_a

      expect(ordered.index(older)).to be < ordered.index(newer)
    end
  end

  context "notification_recipients" do
    let(:app) { create(:errbit_app) }
    let!(:watcher) { create(:errbit_watcher, app: app, email: "watcher@example.com") }
    let(:problem) { create(:errbit_problem, app: app) }
    let(:comment_user) { create(:errbit_user, email: "author@example.com") }
    let(:comment) { build(:errbit_comment, err: problem, user: comment_user) }

    before { create(:errbit_user_watcher, app: app, user: comment_user) }

    it "includes app notification_recipients except the comment user's email" do
      expect(comment.notification_recipients).to eq([watcher.address])
    end
  end

  context "emailable?" do
    let(:app) { create(:errbit_app, notify_on_errs: true) }
    let!(:watcher) { create(:errbit_watcher, app: app, email: "watcher@example.com") }
    let(:problem) { create(:errbit_problem, app: app) }
    let(:comment_user) { create(:errbit_user, email: "author@example.com") }
    let(:comment) { build(:errbit_comment, err: problem, user: comment_user) }

    before { create(:errbit_user_watcher, app: app, user: comment_user) }

    it "is true when the app is emailable and there are recipients other than the comment user" do
      expect(comment.emailable?).to eq(true)
    end

    it "is false when the app is not emailable" do
      app.update!(notify_on_errs: false)

      expect(comment.notification_recipients).to be_any
      expect(comment.emailable?).to eq(false)
    end

    it "is false when the only recipient is the comment user" do
      watcher.destroy
      app.reload

      expect(app.emailable?).to eq(true)
      expect(comment.emailable?).to eq(false)
    end
  end
end
