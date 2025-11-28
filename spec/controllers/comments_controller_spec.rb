# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommentsController, type: :controller do
  let(:app) { Fabricate(:app) }
  let(:err) { Fabricate(:err, problem: Fabricate(:problem, app: app, environment: "production")) }

  describe "POST /apps/:app_id/errs/:id/comments/create" do
    render_views

    before do
      sign_in create(:user, admin: true)
    end

    context "successful comment creation" do
      let(:problem) { Fabricate(:problem) }
      let(:user) { create(:user) }

      before do
        post :create, params: {
          app_id: problem.app.id,
          problem_id: problem.id,
          comment: {
            body: "One test comment",
            user_id: user.id
          }
        }
        problem.reload
      end

      it "should create the comment" do
        expect(problem.comments.size).to eq(1)
      end

      it "should redirect to problem page" do
        expect(response).to redirect_to(app_problem_path(problem.app, problem))
      end
    end
  end

  describe "DELETE /apps/:app_id/errs/:id/comments/:id/destroy" do
    render_views

    before do
      sign_in create(:user, admin: true)
    end

    context "successful comment deletion" do
      let(:problem) { Fabricate(:problem_with_comments) }
      let(:comment) { problem.reload.comments.first }

      before do
        delete :destroy, params: {
          app_id: problem.app.id,
          problem_id: problem.id,
          id: comment.id.to_s
        }
        problem.reload
      end

      it "should delete the comment" do
        expect(problem.comments.detect { |c| c.id.to_s == comment.id }).to eq(nil)
      end

      it "should redirect to problem page" do
        expect(response).to redirect_to(app_problem_path(problem.app, problem))
      end
    end
  end
end
