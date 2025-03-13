describe "problems/show.html.haml", type: "view" do
  let(:problem) { Fabricate(:problem) }
  let(:comment) { Fabricate(:comment) }
  let(:pivotal_tracker) do
    Class.new(ErrbitPlugin::MockIssueTracker) do
      def self.label
        "pivotal"
      end

      def self.icons
        {}
      end

      def configured?
        true
      end
    end
  end
  let(:github_tracker) do
    Class.new(ErrbitPlugin::MockIssueTracker) do
      def self.label
        "github"
      end

      def self.icons
        {}
      end

      def configured?
        true
      end
    end
  end
  let(:trackers) do
    {
      "github"  => github_tracker,
      "pivotal" => pivotal_tracker
    }
  end
  let(:app) { AppDecorator.new(problem.app) }

  before do
    allow(view).to receive(:app).and_return(app)
    allow(view).to receive(:problem).and_return(problem)

    assign :comment, comment
    assign :notices, problem.notices.page(1).per(1)
    assign :notice, problem.notices.first

    allow(controller).to receive(:current_user).and_return(Fabricate(:user))
  end

  def with_issue_tracker(tracker, _problem)
    allow(ErrbitPlugin::Registry).to receive(:issue_trackers).and_return(trackers)
    app.issue_tracker = IssueTrackerDecorator.new(
      IssueTracker.new type_tracker: tracker, options: {
        api_token:  "token token token",
        project_id: "1234"
      })
  end

  describe "content_for :action_bar" do
    def action_bar
      view.content_for(:action_bar)
    end

    it "should confirm the 'resolve' link by default" do
      render
      expect(action_bar).to have_selector(
        format(
          'a.resolve[data-confirm="%s"]',
          I18n.t("problems.confirm.resolve_one")
        )
      )
    end

    it "should confirm the 'resolve' link if configuration is unset" do
      allow(Errbit::Config).to receive(:confirm_err_actions).and_return(nil)
      render
      expect(action_bar).to have_selector(
        format(
          'a.resolve[data-confirm="%s"]',
          I18n.t("problems.confirm.resolve_one")
        )
      )
    end

    it "should not confirm the 'resolve' link if configured not to" do
      allow(Errbit::Config).to receive(:confirm_err_actions).and_return(false)
      render
      expect(action_bar).not_to have_selector('a.resolve[data-confirm=""]')
    end

    it "should link 'up' to HTTP_REFERER if is set" do
      url = "http://localhost:3000/problems"
      controller.request.env["HTTP_REFERER"] = url
      render
      expect(action_bar).to have_selector("span a.up[href='#{url}']", text: "up")
    end

    it "should link 'up' to app_problems_path if HTTP_REFERER isn't set'" do
      controller.request.env["HTTP_REFERER"] = nil
      problem = Fabricate(:problem_with_comments)

      allow(view).to receive(:problem).and_return(problem)
      allow(view).to receive(:app).and_return(problem.app)
      render

      expect(action_bar).to have_selector("span a.up[href='#{app_problems_path(problem.app)}']", text: "up")
    end

    context "create issue links" do
      let(:app) { Fabricate(:app, github_repo: "test_user/test_repo") }

      it "should allow creating issue for github if application has a github tracker" do
        problem = Fabricate(:problem_with_comments, app: app)
        with_issue_tracker("github", problem)
        allow(view).to receive(:problem).and_return(problem)
        allow(view).to receive(:app).and_return(problem.app)
        render

        expect(action_bar).to have_selector("span a.create-issue", text: "create issue")
      end

      context "without issue tracker associate on app" do
        let(:problem) { Problem.new(new_record: false, app: app) }
        let(:app) { App.new(new_record: false) }

        it "not see link to create issue" do
          render
          expect(view.content_for(:action_bar)).to_not match(/create issue/)
        end
      end

      context "with tracker associate on app" do
        before do
          with_issue_tracker("pivotal", problem)
        end

        context "with app having github_repo" do
          let(:app) { App.new(new_record: false, github_repo: "foo/bar") }
          let(:problem) { Problem.new(new_record: false, app: app) }

          before do
            problem.issue_link = nil
            user = Fabricate(:user, github_login: "test_user", github_oauth_token: "abcdef")

            allow(controller).to receive(:current_user).and_return(user)
          end

          it "links to the associated tracker" do
            render
            expect(view.content_for(:action_bar)).to match(".create-issue")
          end
        end

        context "without app having github_repo" do
          context "with problem without issue link" do
            before do
              problem.issue_link = nil
            end
            it "not see link if no issue tracker" do
              render
              expect(view.content_for(:action_bar)).to match(/create issue/)
            end
          end

          context "with problem with issue link" do
            before do
              problem.issue_link = "http://foo"
            end

            it "not see link if no issue tracker" do
              render
              expect(view.content_for(:action_bar)).to_not match(/create issue/)
            end
          end
        end
      end
    end
  end

  describe "content_for :comments" do
    before do
      problem = Fabricate(:problem_with_comments)
      allow(view).to receive(:problem).and_return(problem)
      allow(view).to receive(:app).and_return(problem.app)
      allow(Errbit::Config).to receive(:use_gravatar).and_return(true)
    end

    it "displays comments and new comment form" do
      render

      expect(view.content_for(:comments)).to include("Test comment")
      expect(view.content_for(:comments)).to have_selector('img[src^="http://www.gravatar.com/avatar"]')
      expect(view.content_for(:comments)).to include("Add a comment")
    end

    it "displays existing comments with configured tracker" do
      with_issue_tracker("pivotal", problem)
      render

      expect(view.content_for(:comments)).to include("Test comment")
      expect(view.content_for(:comments)).to have_selector('img[src^="http://www.gravatar.com/avatar"]')
    end

    it "displays comment when comment has no user" do
      with_issue_tracker("pivotal", problem)

      first_comment = view.problem.comments.first
      first_comment.user.destroy
      first_comment.reload

      render

      expect(view.content_for(:comments)).to include("Test comment")
      expect(view.content_for(:comments)).to include("Unknown User")
      expect(view.content_for(:comments)).to have_selector('img[src^="http://www.gravatar.com/avatar"]')
    end
  end
end
