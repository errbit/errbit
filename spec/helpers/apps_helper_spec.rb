# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppsHelper, type: :helper do
  describe "#link_to_copy_attributes_from_other_app" do
    context "when there is only one app" do
      it "returns nil" do
        create(:errbit_app)

        expect(helper.link_to_copy_attributes_from_other_app).to be_nil
      end
    end

    context "when there are no apps" do
      it "returns nil" do
        expect(helper.link_to_copy_attributes_from_other_app).to be_nil
      end
    end

    context "when there are multiple apps" do
      let!(:current_app) { create(:errbit_app, name: "Current") }
      let!(:other_app) { create(:errbit_app, name: "Other") }

      before { assign(:app, current_app) }

      it "renders a copy-settings link" do
        html = helper.link_to_copy_attributes_from_other_app

        expect(html).to include('class="button copy_config"')
        expect(html).to include("copy settings from another app")
      end

      it "renders a select tag with the other apps as options" do
        html = helper.link_to_copy_attributes_from_other_app

        expect(html).to include('class="choose_other_app"')
        expect(html).to include("Other")
        expect(html).to include(%(value="#{other_app.id}"))
      end

      it "does not include the current app among the options" do
        html = helper.link_to_copy_attributes_from_other_app

        expect(html).not_to include(%(value="#{current_app.id}"))
      end

      it "includes a blank prompt option" do
        expect(helper.link_to_copy_attributes_from_other_app).to include("[choose app]")
      end

      it "hides the select element by default" do
        expect(helper.link_to_copy_attributes_from_other_app).to include('style="display: none;"')
      end
    end
  end

  describe "attribute detection across apps" do
    let(:plain_app) do
      double(
        github_repo?: false,
        bitbucket_repo?: false,
        issue_tracker_configured?: false,
        notification_service_configured?: false
      )
    end

    let(:fancy_app) do
      double(
        github_repo?: true,
        bitbucket_repo?: true,
        issue_tracker_configured?: true,
        notification_service_configured?: true
      )
    end

    describe "#any_github_repos?" do
      it "is true when at least one app has a github repo" do
        allow(helper).to receive(:apps).and_return([plain_app, fancy_app])

        expect(helper.any_github_repos?).to be true
      end

      it "is false when no apps have a github repo" do
        allow(helper).to receive(:apps).and_return([plain_app])

        expect(helper.any_github_repos?).to be false
      end

      it "memoizes the result so apps is only iterated once" do
        expect(helper).to receive(:apps).once.and_return([plain_app])

        helper.any_github_repos?
        helper.any_github_repos?
      end
    end

    describe "#any_bitbucket_repos?" do
      it "is true when at least one app has a bitbucket repo" do
        allow(helper).to receive(:apps).and_return([plain_app, fancy_app])

        expect(helper.any_bitbucket_repos?).to be true
      end

      it "is false when no apps have a bitbucket repo" do
        allow(helper).to receive(:apps).and_return([plain_app])

        expect(helper.any_bitbucket_repos?).to be false
      end
    end

    describe "#any_issue_trackers?" do
      it "is true when at least one app has an issue tracker configured" do
        allow(helper).to receive(:apps).and_return([plain_app, fancy_app])

        expect(helper.any_issue_trackers?).to be true
      end

      it "is false when no apps have an issue tracker configured" do
        allow(helper).to receive(:apps).and_return([plain_app])

        expect(helper.any_issue_trackers?).to be false
      end
    end

    describe "#any_notification_services?" do
      it "reflects the detection results once they have been populated" do
        allow(helper).to receive(:apps).and_return([plain_app, fancy_app])
        helper.any_github_repos?

        expect(helper.any_notification_services?).to be true
      end

      it "is false when detection has populated the result as false" do
        allow(helper).to receive(:apps).and_return([plain_app])
        helper.any_github_repos?

        expect(helper.any_notification_services?).to be false
      end
    end
  end
end
