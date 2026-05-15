# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::CommentsController, type: :controller do
  context "when logged in" do
    let(:user) { create(:errbit_user) }

    describe "GET /api/v1/problems/:problem_id/comments" do
      let!(:problem) { create(:errbit_problem) }

      before do
        create(:errbit_comment, err: problem)
        create(:errbit_comment, err: problem)
        create(:errbit_comment)
      end

      it "returns JSON when JSON is requested" do
        get :index, params: {problem_id: problem.id, auth_token: user.authentication_token, format: "json"}

        expect { response.parsed_body }.not_to raise_error
      end

      it "returns XML when XML is requested" do
        get :index, params: {problem_id: problem.id, auth_token: user.authentication_token, format: "xml"}

        expect(Nokogiri::XML(response.body).errors).to be_empty
      end

      it "returns JSON by default" do
        get :index, params: {problem_id: problem.id, auth_token: user.authentication_token}

        expect { response.parsed_body }.not_to raise_error
      end

      it "returns only the comments for the requested problem" do
        get :index, params: {problem_id: problem.id, auth_token: user.authentication_token}

        expect(response).to be_successful
        expect(JSON.parse(response.body).length).to eq(2)
      end
    end

    describe "POST /api/v1/problems/:problem_id/comments" do
      let!(:problem) { create(:errbit_problem) }

      context "with valid params" do
        it "creates a comment" do
          expect {
            post :create, params: {problem_id: problem.id, auth_token: user.authentication_token, comment: {body: "I'll take a look at it."}}
          }.to change(Errbit::Comment, :count).by(1)

          expect(response).to be_successful
        end
      end

      context "with invalid params" do
        it "does not create a comment and returns 422 with errors" do
          expect {
            post :create, params: {problem_id: problem.id, auth_token: user.authentication_token, comment: {body: nil}}
          }.not_to change(Errbit::Comment, :count)

          expect(response).not_to be_successful

          expect(JSON.parse(response.body)).to eq("errors" => ["Body can't be blank"])
        end
      end
    end
  end
end
