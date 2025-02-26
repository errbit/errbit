describe ProblemsController, type: 'controller' do
  it_requires_authentication for:    {
    index: :get, show: :get, resolve: :put, search: :get
  },
                             params: { app_id: 'dummyid', id: 'dummyid' }

  let(:app) { Fabricate(:app) }
  let(:err) { Fabricate(:err, problem: problem) }
  let(:user) { Fabricate(:user) }
  let(:problem) { Fabricate(:problem, app: app, environment: "production") }

  describe "GET /problems" do
    before(:each) do
      sign_in user
      @problem = Fabricate(:notice, err: Fabricate(:err, problem: Fabricate(:problem, app: app, environment: "production"))).problem
    end

    context "pagination" do
      before(:each) do
        35.times { Fabricate :err }
      end

      it "should have default per_page value for user" do
        get :index
        expect(controller.problems.to_a.size).to eq User::PER_PAGE
      end

      it "should be able to override default per_page value" do
        user.update_attribute :per_page, 10
        get :index
        expect(controller.problems.to_a.size).to eq 10
      end
    end

    context 'with environment filters' do
      before(:each) do
        environments = %w(production test development staging)
        20.times do |i|
          Fabricate(:problem, environment: environments[i % environments.length])
        end
      end

      context 'no params' do
        it 'shows problems for all environments' do
          get :index
          expect(controller.problems.size).to eq 21
        end
      end

      context 'environment production' do
        it 'shows problems for just production' do
          get :index, params: { environment: 'production' }
          expect(controller.problems.size).to eq 6
        end
      end

      context 'environment staging' do
        it 'shows problems for just staging' do
          get :index, params: { environment: 'staging' }
          expect(controller.problems.size).to eq 5
        end
      end

      context 'environment development' do
        it 'shows problems for just development' do
          get :index, params: { environment: 'development' }
          expect(controller.problems.size).to eq 5
        end
      end

      context 'environment test' do
        it 'shows problems for just test' do
          get :index, params: { environment: 'test' }
          expect(controller.problems.size).to eq 5
        end
      end
    end
  end

  describe "GET /problems - previously all" do
    it "gets a paginated list of all problems" do
      sign_in Fabricate(:user)
      problems = Kaminari.paginate_array((1..30).to_a)
      3.times { problems << Fabricate(:err).problem }
      3.times { problems << Fabricate(:err, problem: Fabricate(:problem, resolved: true)).problem }
      expect(Problem).to receive(:ordered_by).and_return(
        double('proxy', page: double('other_proxy', per: problems))
      )
      get :index, params: { all_errs: true }
      expect(controller.problems).to eq problems
    end
  end

  describe "GET /problems/search" do
    before do
      sign_in user
      @app      = Fabricate(:app)
      @problem1 = Fabricate(:problem, app: @app, message: "Most important")
      @problem2 = Fabricate(:problem, app: @app, message: "Very very important")
    end

    it "renders successfully" do
      get :search
      expect(response).to be_successful
    end

    it "renders index template" do
      get :search
      expect(response).to render_template('problems/index')
    end

    it "searches problems for given string" do
      get :search, params: { search: "\"Most important\"" }
      expect(controller.problems).to include(@problem1)
      expect(controller.problems).to_not include(@problem2)
    end

    it "works when given string is empty" do
      get :search, params: { search: "" }
      expect(controller.problems).to include(@problem1)
      expect(controller.problems).to include(@problem2)
    end
  end

  # you do not need an app id, strictly speaking, to find
  # a problem, and if your metrics system does not happen
  # to know the app id, but does know the problem id,
  # it can be handy to have a way to link in to errbit.
  describe "GET /problems/:id" do
    before do
      sign_in user
    end

    it "should redirect to the standard problems page" do
      get :show_by_id, params: { id: err.problem.id }
      expect(response).to redirect_to(app_problem_path(app, err.problem.id))
    end
  end

  describe "GET /apps/:app_id/problems/:id" do
    before do
      sign_in user
    end

    it "finds the app" do
      get :show, params: { app_id: app.id, id: err.problem.id }
      expect(controller.app).to eq app
    end

    it "finds the problem" do
      get :show, params: { app_id: app.id, id: err.problem.id }
      expect(controller.problem).to eq err.problem
    end

    it "successfully render page" do
      get :show, params: { app_id: app.id, id: err.problem.id }
      expect(response).to be_successful
    end

    context "when rendering views" do
      render_views

      it "successfully renders the view even when there are no notices attached to the problem" do
        expect(err.problem.notices).to be_empty
        get :show, params: { app_id: app.id, id: err.problem.id }
        expect(response).to be_successful
      end
    end

    context 'pagination' do
      let!(:notices) do
        3.times.reduce([]) do |coll, i|
          coll << Fabricate(:notice, err: err, created_at: (i.seconds.from_now))
        end
      end

      it "paginates the notices 1 at a time, starting with the most recent" do
        get :show, params: { app_id: app.id, id: err.problem.id }
        expect(assigns(:notices).entries.count).to eq 1
        expect(assigns(:notices)).to include(notices.last)
      end

      it "paginates the notices 1 at a time, based on then notice param" do
        get :show, params: { app_id: app.id, id: err.problem.id, notice: 3 }
        expect(assigns(:notices).entries.count).to eq 1
        expect(assigns(:notices)).to include(notices.first)
      end
    end
  end

  describe "GET /apps/:app_id/problems/:id/xhr_sparkline" do
    before do
      sign_in user
    end

    it "renders without error" do
      get :xhr_sparkline, params: { app_id: app.id, id: err.problem.id }
      expect(response).to be_successful
    end
  end

  describe "PUT /apps/:app_id/problems/:id/resolve" do
    before do
      sign_in user

      @err = Fabricate(:err)
    end

    it 'finds the app and the problem' do
      put :resolve, params: { app_id: @err.app.id, id: @err.problem.id }
      expect(controller.app).to eq @err.app
      expect(controller.problem).to eq @err.problem
    end

    it "should resolve the issue" do
      put :resolve, params: { app_id: @err.app.id, id: @err.problem.id }
      expect(@err.problem.reload.resolved).to be(true)
    end

    it "should display a message" do
      put :resolve, params: { app_id: @err.app.id, id: @err.problem.id }
      expect(request.flash[:success]).to match(/Great news/)
    end

    it "should redirect to the app page" do
      request.env["HTTP_REFERER"] = app_path(@err.app)
      put :resolve, params: { app_id: @err.app.id, id: @err.problem.id }
      expect(response).to redirect_to(app_path(@err.app))
    end

    it "should redirect back to problems page" do
      request.env["HTTP_REFERER"] = problems_path
      put :resolve, params: { app_id: @err.app.id, id: @err.problem.id }
      expect(response).to redirect_to(problems_path)
    end
  end

  describe "POST /apps/:app_id/problems/:id/create_issue" do
    before { sign_in user }

    context "when app has a issue tracker" do
      let(:notice) { NoticeDecorator.new(Fabricate :notice) }
      let(:problem) { ProblemDecorator.new(notice.problem) }
      let(:issue_tracker) do
        Fabricate(:issue_tracker).tap do |t|
          t.instance_variable_set(:@tracker, ErrbitPlugin::MockIssueTracker.new(t.options))
        end
      end

      before do
        problem.app.issue_tracker = issue_tracker
        allow(controller).to receive(:problem).and_return(problem)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "should redirect to problem page" do
        post :create_issue, params: { app_id: problem.app.id, id: problem.id }
        expect(response).to redirect_to(app_problem_path(problem.app, problem))
        expect(flash[:error]).to be_blank
      end

      it "should save the right title" do
        post :create_issue, params: { app_id: problem.app.id, id: problem.id }
        title = "[#{problem.environment}][#{problem.where}] #{problem.message.to_s.truncate(100)}"
        line = issue_tracker.tracker.output.shift
        expect(line[0]).to eq(title)
      end

      it "should renders the issue body" do
        post :create_issue, params: { app_id: problem.app.id, id: problem.id, format: 'html' }
        expect(response).to render_template("issue_trackers/issue")
      end

      it "should update the problem" do
        post :create_issue, params: { app_id: problem.app.id, id: problem.id }
        expect(problem.issue_link).to eq("http://example.com/mock-errbit")
        expect(problem.issue_type).to eq("mock")
      end

      context "when rendering views" do
        render_views

        it "should save the right body" do
          post :create_issue, params: { app_id: problem.app.id, id: problem.id, format: 'html' }
          line = issue_tracker.tracker.output.shift
          expect(line[1]).to include(app_problem_url problem.app, problem)
        end

        it "should render whatever the issue tracker says" do
          allow_any_instance_of(Issue).to receive(:render_body_args).and_return(
            [{ inline: 'one <%= problem.id %> two' }])
          post :create_issue, params: { app_id: problem.app.id, id: problem.id, format: 'html' }
          line = issue_tracker.tracker.output.shift
          expect(line[1]).to eq("one #{problem.id} two")
        end
      end
    end

    context "when app has no issue tracker" do
      it "should redirect to problem page" do
        post :create_issue, params: { app_id: problem.app.id, id: problem.id }
        expect(response).to redirect_to(app_problem_path(problem.app, problem))
        expect(flash[:error]).to eql "This app has no issue tracker"
      end
    end
  end

  describe "POST /apps/:app_id/problems/:id/close_issue" do
    before { sign_in user }

    context "when app has a issue tracker" do
      let(:notice) { NoticeDecorator.new(Fabricate :notice) }
      let(:problem) { ProblemDecorator.new(notice.problem) }
      let(:issue_tracker) do
        Fabricate(:issue_tracker).tap do |t|
          t.instance_variable_set(:@tracker, ErrbitPlugin::MockIssueTracker.new(t.options))
        end
      end

      before do
        problem.app.issue_tracker = issue_tracker
        allow(controller).to receive(:problem).and_return(problem)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "should redirect to problem page" do
        post :close_issue, params: { app_id: problem.app.id, id: problem.id }
        expect(response).to redirect_to(app_problem_path(problem.app, problem))
        expect(flash[:error]).to be_blank
      end
    end

    context "when app has no issue tracker" do
      it "should redirect to problem page" do
        post :close_issue, params: { app_id: problem.app.id, id: problem.id }
        expect(response).to redirect_to(app_problem_path(problem.app, problem))
        expect(flash[:error]).to eql "This app has no issue tracker"
      end
    end
  end

  describe "DELETE /apps/:app_id/problems/:id/unlink_issue" do
    before(:each) do
      sign_in user
    end

    context "problem with issue" do
      let(:err) { Fabricate(:err, problem: Fabricate(:problem, issue_link: "http://some.host")) }

      before(:each) do
        delete :unlink_issue, params: { app_id: err.app.id, id: err.problem.id }
        err.problem.reload
      end

      it "should redirect to problem page" do
        expect(response).to redirect_to(app_problem_path(err.app, err.problem))
      end

      it "should clear issue link" do
        expect(err.problem.issue_link).to be_nil
      end
    end

    context "err without issue" do
      let(:err) { Fabricate :err }

      before(:each) do
        delete :unlink_issue, params: { app_id: err.app.id, id: err.problem.id }
        err.problem.reload
      end

      it "should redirect to problem page" do
        expect(response).to redirect_to(app_problem_path(err.app, err.problem))
      end
    end
  end

  describe "Bulk Actions" do
    before(:each) do
      sign_in user
      @problem1 = Fabricate(:err, problem: Fabricate(:problem, resolved: true)).problem
      @problem2 = Fabricate(:err, problem: Fabricate(:problem, resolved: false)).problem
    end

    context "POST /problems/merge_several" do
      it "should require at least two problems" do
        post :merge_several, params: { problems: [@problem1.id.to_s] }
        expect(request.flash[:notice]).to eql I18n.t('controllers.problems.flash.need_two_errors_merge')
      end

      it "should merge the problems" do
        expect(ProblemMerge).to receive(:new).and_return(double(merge: true))
        post :merge_several, params: { problems: [@problem1.id.to_s, @problem2.id.to_s] }
      end
    end

    context "POST /problems/unmerge_several" do
      it "should require at least one problem" do
        post :unmerge_several, params: { problems: [] }
        expect(request.flash[:notice]).to eql I18n.t('controllers.problems.flash.no_select_problem')
      end

      it "should unmerge a merged problem" do
        merged_problem = Problem.merge!(@problem1, @problem2)
        expect(merged_problem.errs.length).to eq 2
        expect do
          post :unmerge_several, params: { problems: [merged_problem.id.to_s] }
          expect(merged_problem.reload.errs.length).to eq 1
        end.to change(Problem, :count).by(1)
      end
    end

    context "POST /problems/resolve_several" do
      it "should require at least one problem" do
        post :resolve_several, params: { problems: [] }
        expect(request.flash[:notice]).to eql I18n.t('controllers.problems.flash.no_select_problem')
      end

      it "should resolve the issue" do
        post :resolve_several, params: { problems: [@problem2.id.to_s] }
        expect(@problem2.reload.resolved?).to eq true
      end

      it "should display a message about 1 err" do
        post :resolve_several, params: { problems: [@problem2.id.to_s] }
        expect(flash[:success]).to match(/1 error has been resolved/)
      end

      it "should display a message about 2 errs" do
        post :resolve_several, params: { problems: [@problem1.id.to_s, @problem2.id.to_s] }
        expect(flash[:success]).to match(/2 errors have been resolved/)
        expect(controller.selected_problems).to eq [@problem1, @problem2]
      end
    end

    context "POST /problems/unresolve_several" do
      it "should require at least one problem" do
        post :unresolve_several, params: { problems: [] }
        expect(request.flash[:notice]).to eql I18n.t('controllers.problems.flash.no_select_problem')
      end

      it "should unresolve the issue" do
        post :unresolve_several, params: { problems: [@problem1.id.to_s] }
        expect(@problem1.reload.resolved?).to eq false
      end
    end

    context "POST /problems/destroy_several" do
      it "should delete the problems" do
        expect do
          post :destroy_several, params: { problems: [@problem1.id.to_s] }
        end.to change(Problem, :count).by(-1)
      end
    end

    describe "POST /apps/:app_id/problems/destroy_all" do
      before do
        sign_in user
        @app      = Fabricate(:app)
        @problem1 = Fabricate(:problem, app: @app)
        @problem2 = Fabricate(:problem, app: @app)
      end

      it "destroys all problems" do
        expect do
          post :destroy_all, params: { app_id: @app.id }
        end.to change(Problem, :count).by(-2)
        expect(controller.app).to eq @app
      end

      it "should display a message" do
        put :destroy_all, params: { app_id: @app.id }
        expect(request.flash[:success]).to match(/be deleted/)
      end

      it "should redirect back to the app page" do
        request.env["HTTP_REFERER"] = edit_app_path(@app)
        put :destroy_all, params: { app_id: @app.id }
        expect(response).to redirect_to(edit_app_path(@app))
      end
    end
  end
end
