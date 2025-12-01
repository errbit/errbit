# frozen_string_literal: true

require "rails_helper"

RSpec.describe Comment, type: :model do
  context "validations" do
    it "should require a body" do
      comment = build(:comment, body: nil)
      expect(comment.valid?).to eq(false)
      expect(comment.errors[:body]).to include("can't be blank")
    end
  end

  context "notification_recipients" do
    let(:app) { create(:app) }
    let!(:watcher) { Fabricate(:watcher, app: app) }
    let(:err) { Fabricate(:problem, app: app) }
    let(:comment_user) { create(:user, email: "author@example.com") }
    let(:comment) { build(:comment, err: err, user: comment_user) }

    before do
      Fabricate(:user_watcher, app: app, user: comment_user)
    end

    it "includes app notification_recipients except user email" do
      expect(comment.notification_recipients).to eq([watcher.address])
    end
  end

  context "emailable?" do
    let(:app) { create(:app, notify_on_errs: true) }
    let!(:watcher) { Fabricate(:watcher, app: app) }
    let(:err) { Fabricate(:problem, app: app) }
    let(:comment_user) { create(:user, email: "author@example.com") }
    let(:comment) { build(:comment, err: err, user: comment_user) }

    before do
      Fabricate(:user_watcher, app: app, user: comment_user)
    end

    it "should be true if app is emailable? and there are notification recipients" do
      expect(comment.emailable?).to eq(true)
    end

    it "should be false if app is not emailable?" do
      app.update_attribute(:notify_on_errs, false)
      expect(comment.notification_recipients).to be_any
      expect(comment.emailable?).to eq(false)
    end

    it "should be false if there are no notification recipients" do
      watcher.destroy
      expect(app.emailable?).to eq(true)
      expect(comment.emailable?).to eq(false)
    end
  end
end
