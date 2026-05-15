# frozen_string_literal: true

require "rails_helper"

RSpec.describe NoticesController, type: :controller do
  it_requires_authentication for: {locate: :get}

  let(:notice) { create(:errbit_notice) }
  let(:xml) { Rails.root.join("spec/fixtures/hoptoad_test_notice.xml").read }
  let(:app) { create(:errbit_app) }
  let(:error_report) { double(valid?: true, generate_notice!: true, notice: notice, should_keep?: true) }

  context "with the notices API" do
    context "with bogus xml" do
      it "returns an error" do
        post :create, body: "<r><b>notxml</r>", format: :xml

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to eq("The provided XML was not well-formed")
      end
    end

    context "with valid params" do
      before do
        expect(Errbit::ErrorReport).to receive(:new).with(xml).and_return(error_report)
      end

      context "with xml in the raw POST body" do
        before { post :create, body: xml, format: :xml }

        it "generates a notice and renders an XML payload" do
          expect(response).to be_successful
          expect(response.body).to match(%r{<id[^>]*>#{notice.id}</id>})
          expect(response.body).to match(%r{<url[^>]*>(.+)#{locate_path(notice.id)}</url>})
        end
      end

      context "with xml in a data POST param" do
        before { post :create, params: {data: xml, format: :xml} }

        it "generates a notice and renders an XML payload" do
          expect(response).to be_successful
          expect(response.body).to match(%r{<id[^>]*>#{notice.id}</id>})
          expect(response.body).to match(%r{<url[^>]*>(.+)#{locate_path(notice.id)}</url>})
        end
      end

      context "with xml in a data GET param" do
        before { get :create, params: {data: xml, format: :xml} }

        it "generates a notice and renders an XML payload" do
          expect(response).to be_successful
          expect(response.body).to match(%r{<id[^>]*>#{notice.id}</id>})
          expect(response.body).to match(%r{<url[^>]*>(.+)#{locate_path(notice.id)}</url>})
        end
      end

      context "with an invalid API key" do
        let(:error_report) { double(valid?: false) }

        it "returns 422" do
          post :create, params: {format: :xml, data: xml}

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    context "without the params needed" do
      it "returns 400" do
        post :create, format: :xml

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to eq("Need a data params in GET or raw post data")
      end
    end
  end

  describe "GET /locate/:id" do
    context "when logged in as an admin" do
      before { sign_in create(:errbit_user, admin: true) }

      it "locates the notice and redirects to its problem page" do
        problem = create(:errbit_problem, app: app, environment: "production")
        err = create(:errbit_err, problem: problem)
        located = create(:errbit_notice, err: err, app: app)

        get :locate, params: {id: located.id}

        expect(response).to redirect_to(app_problem_path(problem.app, problem))
      end
    end
  end

  describe "GET /notices/:id" do
    context "when logged in as an admin" do
      before { sign_in create(:errbit_user, admin: true) }

      it "redirects to the problem page with the notice id" do
        problem = create(:errbit_problem, app: app, environment: "production")
        err = create(:errbit_err, problem: problem)
        located = create(:errbit_notice, err: err, app: app)

        get :show_by_id, params: {id: located.id}

        expect(response).to redirect_to(app_problem_path(problem.app, problem, notice_id: located.id))
      end
    end
  end
end
