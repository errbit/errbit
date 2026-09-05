# frozen_string_literal: true

require "rails_helper"

RSpec.describe NoticesController, type: :controller do
  it_requires_authentication for: {locate: :get}

  let(:notice) { create(:notice) }

  let(:app) { create(:app) }

  describe "GET /locate/:id" do
    context "when logged in as an admin" do
      before do
        @user = create(:user, admin: true)
        sign_in @user
      end

      it "should locate notice and redirect to problem" do
        problem = create(:problem, app: app, environment: "production")
        err = create(:err, problem: problem)
        notice = create(:notice, err: err)
        get :locate, params: {id: notice.id}
        expect(response).to redirect_to(app_problem_path(problem.app, problem))
      end
    end
  end

  describe "GET /notices/:id" do
    context "when logged in as an admin" do
      before do
        @user = create(:user, admin: true)
        sign_in @user
      end

      it "should locate notice and redirect to problem with notice_id" do
        problem = create(:problem, app: app, environment: "production")
        err = create(:err, problem: problem)
        notice = create(:notice, err: err)
        get :show_by_id, params: {id: notice.id}
        expect(response).to redirect_to(app_problem_path(problem.app, problem, notice_id: notice.id))
      end
    end
  end
end
