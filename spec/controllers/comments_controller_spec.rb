# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommentsController, type: :controller do
  before { sign_in create(:errbit_user, admin: true) }

  describe "POST /apps/:app_id/problems/:problem_id/comments" do
    context "when create succeeds" do
      let(:problem) { create(:errbit_problem) }

      before do
        post :create, params: {
          app_id: problem.app.id,
          problem_id: problem.id,
          comment: {body: "One test comment"}
        }
      end

      it "creates the comment under the problem" do
        expect(problem.comments.reload.size).to eq(1)
        expect(problem.comments.first.body).to eq("One test comment")
      end

      it "redirects to the problem page" do
        expect(response).to redirect_to(app_problem_path(problem.app, problem))
      end
    end

    context "when create fails (blank body)" do
      let(:problem) { create(:errbit_problem) }

      before do
        post :create, params: {
          app_id: problem.app.id,
          problem_id: problem.id,
          comment: {body: ""}
        }
      end

      it "does not create a comment" do
        expect(problem.comments.reload).to be_empty
      end

      it "flashes the error message" do
        expect(request.flash[:error]).to eq(I18n.t("comments.create.error"))
      end

      it "redirects to the problem page" do
        expect(response).to redirect_to(app_problem_path(problem.app, problem))
      end
    end
  end

  describe "DELETE /apps/:app_id/problems/:problem_id/comments/:id" do
    context "when destroy succeeds" do
      let(:problem) { create(:errbit_problem_with_comments) }
      let(:comment) { problem.reload.comments.first }

      before do
        delete :destroy, params: {
          app_id: problem.app.id,
          problem_id: problem.id,
          id: comment.id.to_s
        }
      end

      it "deletes the comment" do
        expect(Errbit::Comment.where(id: comment.id)).to be_empty
      end

      it "redirects to the problem page" do
        expect(response).to redirect_to(app_problem_path(problem.app, problem))
      end
    end
  end
end
