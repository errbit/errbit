# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Notices management", type: :request do
  let(:errbit_app) { create(:app, api_key: "APIKEY") }

  describe "create a new notice" do
    context "with valid notice" do
      let(:xml) { Rails.root.join("spec/fixtures/hoptoad_test_notice.xml").read }

      it "save a new notice" do
        expect do
          post "/notifier_api/v2/notices", params: {data: xml}
          expect(response).to be_successful
        end.to change(errbit_app.problems, :count).by(1)
      end
    end

    context "with notice with empty backtrace" do
      let(:xml) { Rails.root.join("spec/fixtures/hoptoad_test_notice_without_line_of_backtrace.xml").read }

      it "save a new notice" do
        expect do
          post "/notifier_api/v2/notices", params: {data: xml}
          expect(response).to be_successful
        end.to change(errbit_app.problems, :count).by(1)
      end
    end

    context "with notice with bad api_key" do
      let(:errbit_app) { create(:app) }

      let(:xml) { Rails.root.join("spec/fixtures/hoptoad_test_notice.xml").read }

      it "not save a new notice and return 422" do
        expect do
          post "/notifier_api/v2/notices", params: {data: xml}
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to eq("Your API key is unknown")
        end.not_to change(errbit_app.problems, :count)
      end
    end

    context "with GET request" do
      let(:xml) { Rails.root.join("spec/fixtures/hoptoad_test_notice.xml").read }

      it "save a new notice" do
        expect do
          get "/notifier_api/v2/notices", params: {data: xml}
          expect(response).to be_successful
        end.to change(errbit_app.problems, :count).by(1)
      end
    end
  end

  describe "malformed request parameters" do
    before do
      allow(Errbit::SelfErrorReporter).to receive(:public_environment?).and_return(true)
    end

    it "records the request exception with populated backtrace lines" do
      expect do
        get "/?%ADd+allow_url_include%3d1+%ADd+auto_prepend_file%3dphp://input"
      end.to change(Notice, :count).by(1)

      expect(response).to have_http_status(:bad_request)

      notice = Notice.last
      expect(notice.error_class).to eq("ActionController::BadRequest")
      expect(notice.problem.environment).to eq("test")
      expect(notice.request["url"]).to include("%ADd+allow_url_include")
      expect(notice.request["params"].keys.first).to include("allow_url_include")
      expect(notice.request["cgi-data"]).to include(
        "PATH_INFO" => "/",
        "QUERY_STRING" => "%ADd+allow_url_include%3d1+%ADd+auto_prepend_file%3dphp://input",
        "REQUEST_METHOD" => "GET"
      )
      expect(notice.request["cgi-data"].keys).to include(a_string_matching("secret_key_base"))
      expect(notice.request["cgi-data"].keys).to include(a_string_matching("rack.*errors"))
      expect(notice.request["session"]).to be_a(Hash)

      backtrace = notice.backtrace
      expect(backtrace.lines).to be_present
      expect(backtrace.lines).to all(satisfy { |line| line["file"].present? && line["number"].present? })
    end

    it "records malformed JSON request exceptions with populated backtrace lines" do
      notice_count = Notice.count

      expect do
        post "/notifier_api/v2/notices", params: "{", headers: {
          "CONTENT_TYPE" => "application/json",
          "ACCEPT" => "application/json"
        }
      end.to raise_error(ActionView::Template::Error)

      expect(Notice.count).to eq(notice_count + 1)

      notice = Notice.last
      expect(notice.error_class).to eq("ActionDispatch::Http::Parameters::ParseError")
      expect(notice.request["cgi-data"]).to include(
        "PATH_INFO" => "/notifier_api/v2/notices",
        "REQUEST_METHOD" => "POST",
        "CONTENT_TYPE" => "application/json"
      )
      expect(notice.backtrace.lines).to be_present
      expect(notice.backtrace.lines).to all(
        satisfy { |line| line["file"].present? && line["number"].present? }
      )
    end
  end
end
