# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProblemsController, type: :controller do
  it_requires_authentication(
    for: {index: :get, show: :get, resolve: :patch, search: :get},
    params: {app_id: "dummyid", id: "dummyid"}
  )

  let(:user) { create(:errbit_user) }
  let(:app) { create(:errbit_app) }
  let(:problem) { create(:errbit_problem, app: app, environment: "production") }
  let(:err) { create(:errbit_err, problem: problem) }

  describe "GET /problems" do
    before { sign_in user }

    context "with pagination" do
      before { 35.times { create(:errbit_err) } }

      it "uses the default per_page value" do
        get :index

        expect(controller.problems.to_a.size).to eq(Errbit::User::PER_PAGE)
      end

      it "honors the user's per_page override" do
        user.update!(per_page: 10)

        get :index

        expect(controller.problems.to_a.size).to eq(10)
      end
    end

    context "with environment filters" do
      before do
        environments = %w[production test development staging]
        20.times { |i| create(:errbit_problem, environment: environments[i % environments.length]) }
      end

      context "without env params" do
        it "shows problems for every environment" do
          get :index

          expect(controller.problems.size).to eq(20)
        end
      end

      context "with environment=production" do
        it "filters to just production" do
          get :index, params: {environment: "production"}

          expect(controller.problems.size).to eq(5)
        end
      end

      context "with environment=staging" do
        it "filters to just staging" do
          get :index, params: {environment: "staging"}

          expect(controller.problems.size).to eq(5)
        end
      end
    end
  end

  describe "GET /problems/search" do
    before do
      sign_in user
      @search_app = create(:errbit_app)
      @problem_1 = create(:errbit_problem, app: @search_app, message: "Most important")
      @problem_2 = create(:errbit_problem, app: @search_app, message: "Trivial issue")
    end

    it "renders successfully" do
      get :search

      expect(response).to be_successful
    end

    it "renders the index template" do
      get :search

      expect(response).to render_template("problems/index")
    end

    it "filters problems by the search string" do
      get :search, params: {search: "Most important"}

      expect(controller.problems).to include(@problem_1)
      expect(controller.problems).not_to include(@problem_2)
    end

    it "returns every problem when the search string is empty" do
      get :search, params: {search: ""}

      expect(controller.problems).to include(@problem_1, @problem_2)
    end
  end

  describe "GET /problems/:id (show_by_id)" do
    before { sign_in user }

    it "redirects to the standard problem page" do
      get :show_by_id, params: {id: err.problem.id}

      expect(response).to redirect_to(app_problem_path(app, err.problem))
    end
  end

  describe "GET /apps/:app_id/problems/:id (show)" do
    before { sign_in user }

    it "finds the app" do
      get :show, params: {app_id: app.id, id: err.problem.id}

      expect(controller.app.object).to eq(app)
    end

    it "finds the problem" do
      get :show, params: {app_id: app.id, id: err.problem.id}

      expect(controller.problem.object).to eq(err.problem)
    end

    it "responds successfully" do
      get :show, params: {app_id: app.id, id: err.problem.id}

      expect(response).to be_successful
    end

    context "with notices" do
      let!(:notices) do
        3.times.map { |i| create(:errbit_notice, err: err, created_at: i.seconds.from_now) }
      end

      it "paginates notices 1 at a time, newest first" do
        get :show, params: {app_id: app.id, id: err.problem.id}

        expect(assigns(:notices).entries.count).to eq(1)
        expect(assigns(:notices)).to include(notices.last)
      end

      it "honors the notice page param" do
        get :show, params: {app_id: app.id, id: err.problem.id, notice: 3}

        expect(assigns(:notices).entries.count).to eq(1)
        expect(assigns(:notices)).to include(notices.first)
      end
    end
  end

  describe "GET /apps/:app_id/problems/:id/xhr_sparkline" do
    before { sign_in user }

    it "renders without error" do
      get :xhr_sparkline, params: {app_id: app.id, id: err.problem.id}

      expect(response).to be_successful
    end
  end

  describe "PATCH /apps/:app_id/problems/:id/resolve" do
    let!(:resolvable_err) { create(:errbit_err) }

    before { sign_in user }

    it "finds the app and problem" do
      patch :resolve, params: {app_id: resolvable_err.app.id, id: resolvable_err.problem.id}

      expect(controller.app.object).to eq(resolvable_err.app)
      expect(controller.problem.object).to eq(resolvable_err.problem)
    end

    it "marks the problem as resolved" do
      patch :resolve, params: {app_id: resolvable_err.app.id, id: resolvable_err.problem.id}

      expect(resolvable_err.problem.reload.resolved).to eq(true)
    end

    it "flashes a success message" do
      patch :resolve, params: {app_id: resolvable_err.app.id, id: resolvable_err.problem.id}

      expect(request.flash[:success]).to match(/resolved/)
    end

    it "redirects back to the referer" do
      request.env["HTTP_REFERER"] = app_path(resolvable_err.app)

      patch :resolve, params: {app_id: resolvable_err.app.id, id: resolvable_err.problem.id}

      expect(response).to redirect_to(app_path(resolvable_err.app))
    end
  end

  describe "POST /apps/:app_id/problems/:id/create_issue" do
    before { sign_in user }

    context "when the app has no issue tracker" do
      it "flashes an error and redirects to the problem page" do
        post :create_issue, params: {app_id: problem.app.id, id: problem.id}

        expect(response).to redirect_to(app_problem_path(problem.app, problem))
        expect(flash[:error]).to eq("This app has no issue tracker")
      end
    end

    context "when the app has an issue tracker" do
      let(:decorated_problem) { Errbit::ProblemDecorator.new(problem) }
      let!(:issue_tracker) do
        t = create(:errbit_issue_tracker, app: app)
        # The controller's `app` is a fresh AR load that wouldn't see this
        # instance_variable_set. Stub `controller.problem` below so the issue
        # tracker chain reuses the test's records.
        t.instance_variable_set(:@tracker, ErrbitPlugin::MockIssueTracker.new(t.options))
        t
      end

      before do
        allow(controller).to receive(:problem).and_return(decorated_problem)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "redirects to the problem page without an error" do
        post :create_issue, params: {app_id: app.id, id: problem.id}

        expect(response).to redirect_to(app_problem_path(app, problem))
        expect(flash[:error]).to be_blank
      end

      it "stores the issue link and type on the problem" do
        post :create_issue, params: {app_id: app.id, id: problem.id}

        problem.reload
        expect(problem.issue_link).to eq("http://example.com/mock-errbit")
        expect(problem.issue_type).to eq("mock")
      end
    end
  end

  describe "POST /apps/:app_id/problems/:id/close_issue" do
    before { sign_in user }

    context "when the app has no issue tracker" do
      it "flashes an error and redirects to the problem page" do
        post :close_issue, params: {app_id: problem.app.id, id: problem.id}

        expect(response).to redirect_to(app_problem_path(problem.app, problem))
        expect(flash[:error]).to eq("This app has no issue tracker")
      end
    end
  end

  describe "DELETE /apps/:app_id/problems/:id/unlink_issue" do
    before { sign_in user }

    context "when the problem has an issue link" do
      let!(:linked_err) do
        create(:errbit_err, problem: create(:errbit_problem, app: app, issue_link: "http://some.host"))
      end

      it "clears the issue_link and redirects" do
        delete :unlink_issue, params: {app_id: linked_err.app.id, id: linked_err.problem.id}

        expect(response).to redirect_to(app_problem_path(linked_err.app, linked_err.problem))
        expect(linked_err.problem.reload.issue_link).to be_nil
      end
    end

    context "when the problem has no issue link" do
      it "redirects to the problem page" do
        delete :unlink_issue, params: {app_id: err.app.id, id: err.problem.id}

        expect(response).to redirect_to(app_problem_path(err.app, err.problem))
      end
    end
  end

  describe "Bulk Actions" do
    let!(:problem_1) { create(:errbit_err, problem: create(:errbit_problem, resolved: true)).problem }
    let!(:problem_2) { create(:errbit_err, problem: create(:errbit_problem, resolved: false)).problem }

    before { sign_in user }

    describe "POST /problems/merge_several" do
      context "when only one problem is selected" do
        it "flashes that two are required" do
          post :merge_several, params: {problems: [problem_1.id.to_s]}

          expect(request.flash[:notice]).to eq(I18n.t("controllers.problems.flash.need_two_errors_merge"))
        end
      end

      context "with at least two problems" do
        it "merges them via Errbit::ProblemMerge" do
          expect(Errbit::ProblemMerge).to receive(:new).and_return(double(merge: true))

          post :merge_several, params: {problems: [problem_1.id.to_s, problem_2.id.to_s]}
        end
      end
    end

    describe "POST /problems/unmerge_several" do
      context "without any selected problems" do
        it "flashes the no-select message" do
          post :unmerge_several, params: {problems: []}

          expect(request.flash[:notice]).to eq(I18n.t("controllers.problems.flash.no_select_problem"))
        end
      end

      context "with a merged problem selected" do
        it "splits its errs back into separate problems" do
          merged = Errbit::Problem.merge!(problem_1, problem_2)

          expect(merged.errs.length).to eq(2)

          expect {
            post :unmerge_several, params: {problems: [merged.id.to_s]}
          }.to change(Errbit::Problem, :count).by(1)

          expect(merged.reload.errs.length).to eq(1)
        end
      end
    end

    describe "POST /problems/resolve_several" do
      context "without any selected problems" do
        it "flashes the no-select message" do
          post :resolve_several, params: {problems: []}

          expect(request.flash[:notice]).to eq(I18n.t("controllers.problems.flash.no_select_problem"))
        end
      end

      context "with one selected problem" do
        it "resolves it" do
          post :resolve_several, params: {problems: [problem_2.id.to_s]}

          expect(problem_2.reload.resolved?).to eq(true)
        end

        it "flashes a singular message" do
          post :resolve_several, params: {problems: [problem_2.id.to_s]}

          expect(flash[:success]).to match(/1 error has been resolved/)
        end
      end

      context "with two selected problems" do
        it "flashes a plural message" do
          post :resolve_several, params: {problems: [problem_1.id.to_s, problem_2.id.to_s]}

          expect(flash[:success]).to match(/2 errors have been resolved/)
        end
      end
    end

    describe "POST /problems/unresolve_several" do
      context "without any selected problems" do
        it "flashes the no-select message" do
          post :unresolve_several, params: {problems: []}

          expect(request.flash[:notice]).to eq(I18n.t("controllers.problems.flash.no_select_problem"))
        end
      end

      context "with one selected problem" do
        it "unresolves it" do
          post :unresolve_several, params: {problems: [problem_1.id.to_s]}

          expect(problem_1.reload.resolved?).to eq(false)
        end
      end
    end

    describe "POST /problems/destroy_several" do
      it "enqueues a destroy job" do
        expect(Errbit::DestroyProblemsByIdJob).to receive(:perform_later).with([problem_1.id.to_s])

        post :destroy_several, params: {problems: [problem_1.id.to_s]}
      end
    end

    describe "POST /apps/:app_id/problems/destroy_all" do
      let!(:bulk_app) { create(:errbit_app) }
      let!(:bulk_problem_1) { create(:errbit_problem, app: bulk_app) }
      let!(:bulk_problem_2) { create(:errbit_problem, app: bulk_app) }

      it "enqueues a destroy-all-by-app job" do
        expect(Errbit::DestroyProblemsByAppJob).to receive(:perform_later).with(bulk_app.id)

        post :destroy_all, params: {app_id: bulk_app.id}
      end

      it "flashes a confirmation" do
        patch :destroy_all, params: {app_id: bulk_app.id}

        expect(request.flash[:success]).to match(/be deleted/)
      end

      it "redirects back to the referer" do
        request.env["HTTP_REFERER"] = edit_app_path(bulk_app)

        patch :destroy_all, params: {app_id: bulk_app.id}

        expect(response).to redirect_to(edit_app_path(bulk_app))
      end
    end
  end
end
