require 'spec_helper'

describe "problems/show.html.haml" do
  let(:problem) { Fabricate(:problem) }
  let(:comment) { Fabricate(:comment) }

  before do
    view.stub(:app).and_return(problem.app)
    view.stub(:problem).and_return(problem)

    assign :comment, comment
    assign :notices, problem.notices.page(1).per(1)
    assign :notice, problem.notices.first

    controller.stub(:current_user) { Fabricate(:user) }
  end

  def with_issue_tracker(tracker, problem)
    problem.app.issue_tracker = tracker.new :api_token => "token token token", :project_id => "1234"
    view.stub(:problem).and_return(problem)
    view.stub(:app).and_return(problem.app)
  end

  describe "content_for :action_bar" do
    def action_bar
      view.content_for(:action_bar)
    end

    it "should confirm the 'resolve' link by default" do
      render

      action_bar.should have_selector('a.resolve[data-confirm="Seriously?"]')
    end

    it "should confirm the 'resolve' link if configuration is unset" do
      Errbit::Config.stub(:confirm_resolve_err).and_return(nil)
      render

      action_bar.should have_selector('a.resolve[data-confirm="Seriously?"]')
    end

    it "should not confirm the 'resolve' link if configured not to" do
      Errbit::Config.stub(:confirm_resolve_err).and_return(false)
      render

      action_bar.should have_selector('a.resolve[data-confirm="null"]')
    end

    it "should link 'up' to HTTP_REFERER if is set" do
      url = 'http://localhost:3000/problems'
      controller.request.env['HTTP_REFERER'] = url
      render

      action_bar.should have_selector("span a.up[href='#{url}']", :text => 'up')
    end

    it "should link 'up' to app_problems_path if HTTP_REFERER isn't set'" do
      controller.request.env['HTTP_REFERER'] = nil
      problem = Fabricate(:problem_with_comments)
      view.stub(:problem).and_return(problem)
      view.stub(:app).and_return(problem.app)
      render

      action_bar.should have_selector("span a.up[href='#{app_problems_path(problem.app)}']", :text => 'up')
    end

    context 'create issue links' do
      it 'should allow creating issue for github if current user has linked their github account' do
        user = Fabricate(:user, :github_login => 'test_user', :github_oauth_token => 'abcdef')
        controller.stub(:current_user) { user }

        problem = Fabricate(:problem_with_comments, :app => Fabricate(:app, :github_repo => "test_user/test_repo"))
        view.stub(:problem).and_return(problem)
        view.stub(:app).and_return(problem.app)
        render

        action_bar.should have_selector("span a.github_create.create-issue", :text => 'create issue')
      end

      it 'should allow creating issue for github if application has a github tracker' do
        problem = Fabricate(:problem_with_comments, :app => Fabricate(:app, :github_repo => "test_user/test_repo"))
        with_issue_tracker(GithubIssuesTracker, problem)
        view.stub(:problem).and_return(problem)
        view.stub(:app).and_return(problem.app)
        render

        action_bar.should have_selector("span a.github_create.create-issue", :text => 'create issue')
      end

      context "without issue tracker associate on app" do
        let(:problem){ Problem.new(:new_record => false, :app => app) }
        let(:app) { App.new(:new_record => false) }

        it 'not see link to create issue' do
          view.stub(:problem).and_return(problem)
          view.stub(:app).and_return(problem.app)
          render
          expect(view.content_for(:action_bar)).to_not match(/create issue/)
        end

      end

      context "with lighthouse tracker on app" do
        let(:app) { App.new(:new_record => false, :issue_tracker => tracker ) }
        let(:tracker) {
          IssueTrackers::LighthouseTracker.new(:project_id => 'x')
        }
        context "with problem without issue link" do
          let(:problem){ Problem.new(:new_record => false, :app => app) }
          it 'not see link if no issue tracker' do
            view.stub(:problem).and_return(problem)
            view.stub(:app).and_return(problem.app)
            render
            expect(view.content_for(:action_bar)).to match(/create issue/)
          end

        end

        context "with problem with issue link" do
          let(:problem){ Problem.new(:new_record => false, :app => app, :issue_link => 'http://foo') }

          it 'not see link if no issue tracker' do
            view.stub(:problem).and_return(problem)
            view.stub(:app).and_return(problem.app)
            render
            expect(view.content_for(:action_bar)).to_not match(/create issue/)
          end
        end

      end
    end
  end

  describe "content_for :comments with comments disabled for configured issue tracker" do
    before do
      Errbit::Config.stub(:allow_comments_with_issue_tracker).and_return(false)
      Errbit::Config.stub(:use_gravatar).and_return(true)
    end

    it 'should display comments and new comment form when no issue tracker' do
      problem = Fabricate(:problem_with_comments)
      view.stub(:problem).and_return(problem)
      view.stub(:app).and_return(problem.app)
      render

      view.content_for(:comments).should include('Test comment')
      view.content_for(:comments).should have_selector('img[src^="http://www.gravatar.com/avatar"]')
      view.content_for(:comments).should include('Add a comment')
    end

    context "with issue tracker" do
      it 'should not display the comments section' do
        problem = Fabricate(:problem)
        with_issue_tracker(PivotalLabsTracker, problem)
        render
        view.view_flow.get(:comments).should be_blank
      end

      it 'should display existing comments' do
        problem = Fabricate(:problem_with_comments)
        problem.reload
        with_issue_tracker(PivotalLabsTracker, problem)
        render

        view.content_for(:comments).should include('Test comment')
        view.content_for(:comments).should have_selector('img[src^="http://www.gravatar.com/avatar"]')
        view.content_for(:comments).should_not include('Add a comment')
      end
    end
  end
end

