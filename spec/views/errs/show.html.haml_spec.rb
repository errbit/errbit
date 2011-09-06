require 'spec_helper'

describe "errs/show.html.haml" do
  before do
    err = Factory(:err)
    comment = Factory(:comment)
    assign :err, err
    assign :comment, comment
    assign :app, err.app
    assign :notices, err.notices.ordered.paginate(:page => 1, :per_page => 1)
    assign :notice, err.notices.first
  end

  describe "content_for :action_bar" do

    it "should confirm the 'resolve' link by default" do
      render
      action_bar = String.new(view.instance_variable_get(:@_content_for)[:action_bar])
      resolve_link = action_bar.match(/(<a href.*?(class="resolve").*?>)/)[0]
      resolve_link.should =~ /data-confirm="Seriously\?"/
    end

    it "should confirm the 'resolve' link if configuration is unset" do
      Errbit::Config.stub(:confirm_resolve_err).and_return(nil)
      render
      action_bar = String.new(view.instance_variable_get(:@_content_for)[:action_bar])
      resolve_link = action_bar.match(/(<a href.*?(class="resolve").*?>)/)[0]
      resolve_link.should =~ /data-confirm="Seriously\?"/
    end

    it "should not confirm the 'resolve' link if configured not to" do
      Errbit::Config.stub(:confirm_resolve_err).and_return(false)
      render
      action_bar = String.new(view.instance_variable_get(:@_content_for)[:action_bar])
      resolve_link = action_bar.match(/(<a href.*?(class="resolve").*?>)/)[0]
      resolve_link.should_not =~ /data-confirm=/
    end

  end

  describe "content_for :comments with comments disabled for configured issue tracker" do
    before do
      Errbit::Config.stub(:allow_comments_with_issue_tracker).and_return(false)
    end

    it 'should display comments and new comment form when no issue tracker' do
      err = Factory(:err_with_comments)
      assign :err, err
      assign :app, err.app
      render
      comments_section = String.new(view.instance_variable_get(:@_content_for)[:comments])
      comments_section.should =~ /Test comment/
      comments_section.should =~ /Add a comment/
    end

    context "with issue tracker" do
      def with_issue_tracker(err)
        err.app.issue_tracker = PivotalLabsTracker.new :api_token => "token token token", :project_id => "1234"
        assign :err, err
        assign :app, err.app
      end

      it 'should not display the comments section' do
        with_issue_tracker(Factory(:err))
        render
        view.instance_variable_get(:@_content_for)[:comments].should be_blank
      end

      it 'should display existing comments' do
        with_issue_tracker(Factory(:err_with_comments))
        render
        comments_section = String.new(view.instance_variable_get(:@_content_for)[:comments])
        comments_section.should =~ /Test comment/
        comments_section.should_not =~ /Add a comment/
      end
    end
  end
end

