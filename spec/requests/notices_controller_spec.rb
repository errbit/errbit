# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Notices management", type: :request do
  let!(:errbit_app) { create(:errbit_app, api_key: "APIKEY") }

  describe "POST /notifier_api/v2/notices" do
    context "with a valid notice" do
      let(:xml) { Rails.root.join("spec/fixtures/hoptoad_test_notice.xml").read }

      it "saves a new problem for the app" do
        expect {
          post "/notifier_api/v2/notices", params: {data: xml}
          expect(response).to be_successful
        }.to change { errbit_app.problems.count }.by(1)
      end
    end

    context "with a notice that has an empty backtrace" do
      let(:xml) { Rails.root.join("spec/fixtures/hoptoad_test_notice_without_line_of_backtrace.xml").read }

      it "saves a new problem for the app" do
        expect {
          post "/notifier_api/v2/notices", params: {data: xml}
          expect(response).to be_successful
        }.to change { errbit_app.problems.count }.by(1)
      end
    end

    context "with an unknown api_key" do
      let!(:errbit_app) { create(:errbit_app) }
      let(:xml) { Rails.root.join("spec/fixtures/hoptoad_test_notice.xml").read }

      it "returns 422 and creates no problem" do
        expect {
          post "/notifier_api/v2/notices", params: {data: xml}
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to eq("Your API key is unknown")
        }.not_to change { errbit_app.problems.count }
      end
    end

    context "with a GET request" do
      let(:xml) { Rails.root.join("spec/fixtures/hoptoad_test_notice.xml").read }

      it "saves a new problem for the app" do
        expect {
          get "/notifier_api/v2/notices", params: {data: xml}
          expect(response).to be_successful
        }.to change { errbit_app.problems.count }.by(1)
      end
    end
  end
end
