require 'spec_helper'

describe ErrsController do

  it_requires_authentication :for => {
    :index => :get, :all => :get, :show => :get, :resolve => :put
  },
  :params => {:app_id => 'dummyid', :id => 'dummyid'}

  let(:app) { Factory(:app) }
  let(:err) { Factory(:err, :app => app) }

  describe "GET /errs" do
    render_views
    context 'when logged in as an admin' do
      before(:each) do
        @user = Factory(:admin)
        sign_in @user
        @notice = Factory :notice
        @err = @notice.err
      end

      it "should successfully list errs" do
        get :index
        response.should be_success
        response.body.should match(@err.message)
      end

      it "should list atom feed successfully" do
        get :index, :format => "atom"
        response.should be_success
        response.body.should match(@err.message)
      end

      it "should handle lots of errors" do
        pending "Turning off long running spec"
        1000.times { Factory :notice }
        lambda { get :index }.should_not raise_error
      end

      context "pagination" do
        before(:each) do
          35.times { Factory :err }
        end

        it "should have default per_page value for user" do
          get :index
          assigns(:errs).size.should == User::PER_PAGE
        end

        it "should be able to override default per_page value" do
          @user.update_attribute :per_page, 10
          get :index
          assigns(:errs).size.should == 10
        end
      end
    end

    context 'when logged in as a user' do
      it 'gets a paginated list of unresolved errs for the users apps' do
        sign_in(user = Factory(:user))
        unwatched_err = Factory(:err)
        watched_unresolved_err = Factory(:err, :app => Factory(:user_watcher, :user => user).app, :resolved => false)
        watched_resolved_err = Factory(:err, :app => Factory(:user_watcher, :user => user).app, :resolved => true)
        get :index
        assigns(:errs).should include(watched_unresolved_err)
        assigns(:errs).should_not include(unwatched_err, watched_resolved_err)
      end
    end
  end

  describe "GET /errs/all" do
    context 'when logged in as an admin' do
      it "gets a paginated list of all errs" do
        sign_in Factory(:admin)
        errs = WillPaginate::Collection.new(1,30)
        3.times { errs << Factory(:err) }
        3.times { errs << Factory(:err, :resolved => true)}
        Err.should_receive(:ordered).and_return(
          mock('proxy', :paginate => errs)
        )
        get :all
        assigns(:errs).should == errs
      end
    end

    context 'when logged in as a user' do
      it 'gets a paginated list of all errs for the users apps' do
        sign_in(user = Factory(:user))
        unwatched_err = Factory(:err)
        watched_unresolved_err = Factory(:err, :app => Factory(:user_watcher, :user => user).app, :resolved => false)
        watched_resolved_err = Factory(:err, :app => Factory(:user_watcher, :user => user).app, :resolved => true)
        get :all
        assigns(:errs).should include(watched_resolved_err, watched_unresolved_err)
        assigns(:errs).should_not include(unwatched_err)
      end
    end
  end

  describe "GET /apps/:app_id/errs/:id" do
    render_views

    before do
      3.times { Factory(:notice, :err => err)}
    end

    context 'when logged in as an admin' do
      before do
        sign_in Factory(:admin)
      end

      it "finds the app" do
        get :show, :app_id => app.id, :id => err.id
        assigns(:app).should == app
      end

      it "finds the err" do
        get :show, :app_id => app.id, :id => err.id
        assigns(:err).should == err
      end

      it "successfully render page" do
        get :show, :app_id => app.id, :id => err.id
        response.should be_success
      end

      context "create issue button" do
        let(:button_matcher) { match(/create issue/) }

        it "should not exist for err's app without issue tracker" do
          err = Factory :err
          get :show, :app_id => err.app.id, :id => err.id

          response.body.should_not button_matcher
        end

        it "should exist for err's app with issue tracker" do
          tracker = Factory(:lighthouseapp_tracker)
          err = Factory(:err, :app => tracker.app)
          get :show, :app_id => err.app.id, :id => err.id

          response.body.should button_matcher
        end

        it "should not exist for err with issue_link" do
          tracker = Factory(:lighthouseapp_tracker)
          err = Factory(:err, :app => tracker.app, :issue_link => "http://some.host")
          get :show, :app_id => err.app.id, :id => err.id

          response.body.should_not button_matcher
        end
      end
    end

    context 'when logged in as a user' do
      before do
        sign_in(@user = Factory(:user))
        @unwatched_err = Factory(:err)
        @watched_app = Factory(:app)
        @watcher = Factory(:user_watcher, :user => @user, :app => @watched_app)
        @watched_err = Factory(:err, :app => @watched_app)
      end

      it 'finds the err if the user is watching the app' do
        get :show, :app_id => @watched_app.to_param, :id => @watched_err.id
        assigns(:err).should == @watched_err
      end

      it 'raises a DocumentNotFound error if the user is not watching the app' do
        lambda {
          get :show, :app_id => @unwatched_err.app_id, :id => @unwatched_err.id
        }.should raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end
  end

  describe "PUT /apps/:app_id/errs/:id/resolve" do
    before do
      sign_in Factory(:admin)

      @err = Factory(:err)
      App.stub(:find).with(@err.app.id).and_return(@err.app)
      @err.app.errs.stub(:find).and_return(@err)
      @err.stub(:resolve!)
    end

    it 'finds the app and the err' do
      App.should_receive(:find).with(@err.app.id).and_return(@err.app)
      @err.app.errs.should_receive(:find).and_return(@err)
      put :resolve, :app_id => @err.app.id, :id => @err.id
      assigns(:app).should == @err.app
      assigns(:err).should == @err
    end

    it "should resolve the issue" do
      @err.should_receive(:resolve!).and_return(true)
      put :resolve, :app_id => @err.app.id, :id => @err.id
    end

    it "should display a message" do
      put :resolve, :app_id => @err.app.id, :id => @err.id
      request.flash[:success].should match(/Great news/)
    end

    it "should redirect to the app page" do
      put :resolve, :app_id => @err.app.id, :id => @err.id
      response.should redirect_to(app_path(@err.app))
    end

    it "should redirect back to errs page" do
      request.env["Referer"] = errs_path
      put :resolve, :app_id => @err.app.id, :id => @err.id
      response.should redirect_to(errs_path)
    end
  end

  describe "POST /apps/:app_id/errs/:id/create_issue" do
    render_views

    before(:each) do
      sign_in Factory(:admin)
    end

    context "successful issue creation" do
      context "lighthouseapp tracker" do
        let(:notice) { Factory :notice }
        let(:tracker) { Factory :lighthouseapp_tracker, :app => notice.err.app }
        let(:err) { notice.err }

        before(:each) do
          number = 5
          @issue_link = "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets/#{number}.xml"
          body = "<ticket><number type=\"integer\">#{number}</number></ticket>"
          stub_request(:post, "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets.xml").to_return(:status => 201, :headers => {'Location' => @issue_link}, :body => body )

          post :create_issue, :app_id => err.app.id, :id => err.id
          err.reload
        end

        it "should make request to Lighthouseapp with err params" do
          requested = have_requested(:post, "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets.xml")
          WebMock.should requested.with(:headers => {'X-Lighthousetoken' => tracker.api_token})
          WebMock.should requested.with(:body => /<tag>errbit<\/tag>/)
          WebMock.should requested.with(:body => /<title>\[#{ err.environment }\]\[#{err.where}\] #{err.message.to_s.truncate(100)}<\/title>/)
          WebMock.should requested.with(:body => /<body>.+<\/body>/m)
        end

        it "should redirect to err page" do
          response.should redirect_to( app_err_path(err.app, err) )
        end

        it "should create issue link for err" do
          err.issue_link.should == @issue_link.sub(/\.xml$/, '')
        end
      end

      context "redmine tracker" do
        let(:notice) { Factory :notice }
        let(:tracker) { Factory :redmine_tracker, :app => notice.err.app }
        let(:err) { notice.err }

        before(:each) do
          number = 5
          @issue_link = "#{tracker.account}/issues/#{number}.xml?project_id=#{tracker.project_id}"
          body = "<issue><subject>my subject</subject><id>#{number}</id></issue>"
          stub_request(:post, "#{tracker.account}/issues.xml").to_return(:status => 201, :headers => {'Location' => @issue_link}, :body => body )

          post :create_issue, :app_id => err.app.id, :id => err.id
          err.reload
        end

        it "should make request to Redmine with err params" do
          requested = have_requested(:post, "#{tracker.account}/issues.xml")
          WebMock.should requested.with(:headers => {'X-Redmine-API-Key' => tracker.api_token})
          WebMock.should requested.with(:body => /<project-id>#{tracker.project_id}<\/project-id>/)
          WebMock.should requested.with(:body => /<subject>\[#{ err.environment }\]\[#{err.where}\] #{err.message.to_s.truncate(100)}<\/subject>/)
          WebMock.should requested.with(:body => /<description>.+<\/description>/m)
        end

        it "should redirect to err page" do
          response.should redirect_to( app_err_path(err.app, err) )
        end

        it "should create issue link for err" do
          err.issue_link.should == @issue_link.sub(/\.xml/, '')
        end
      end

      context "redmine tracker" do
        let(:notice) { Factory :notice }
        let(:tracker) { Factory :pivotal_tracker, :app => notice.err.app }
        let(:err) { notice.err }

        before(:each) do
          pending
          number = 5
          @issue_link = "#{tracker.account}/issues/#{number}.xml?project_id=#{tracker.project_id}"
          body = "<issue><subject>my subject</subject><id>#{number}</id></issue>"
          stub_request(:post, "#{tracker.account}/issues.xml").to_return(:status => 201, :headers => {'Location' => @issue_link}, :body => body )

          post :create_issue, :app_id => err.app.id, :id => err.id
          err.reload
        end

        it "should make request to Pivotal Tracker with err params" do
          requested = have_requested(:post, "#{tracker.account}/issues.xml")
          WebMock.should requested.with(:headers => {'X-Redmine-API-Key' => tracker.api_token})
          WebMock.should requested.with(:body => /<project-id>#{tracker.project_id}<\/project-id>/)
          WebMock.should requested.with(:body => /<subject>\[#{ err.environment }\]\[#{err.where}\] #{err.message.to_s.truncate(100)}<\/subject>/)
          WebMock.should requested.with(:body => /<description>.+<\/description>/m)
        end

        it "should redirect to err page" do
          response.should redirect_to( app_err_path(err.app, err) )
        end

        it "should create issue link for err" do
          err.issue_link.should == @issue_link.sub(/\.xml/, '')
        end
      end
    end

    context "absent issue tracker" do
      let(:err) { Factory :err }

      before(:each) do
        post :create_issue, :app_id => err.app.id, :id => err.id
      end

      it "should redirect to err page" do
        response.should redirect_to( app_err_path(err.app, err) )
      end

      it "should set flash error message telling issue tracker of the app doesn't exist" do
        flash[:error].should == "This up has no issue tracker setup."
      end
    end

    context "error during request to a tracker" do
      context "lighthouseapp tracker" do
        let(:tracker) { Factory :lighthouseapp_tracker }
        let(:err) { Factory :err, :app => tracker.app }

        before(:each) do
          stub_request(:post, "http://#{tracker.account}.lighthouseapp.com/projects/#{tracker.project_id}/tickets.xml").to_return(:status => 500)

          post :create_issue, :app_id => err.app.id, :id => err.id
        end

        it "should redirect to err page" do
          response.should redirect_to( app_err_path(err.app, err) )
        end

        it "should notify of connection error" do
          flash[:error].should == "There was an error during issue creation. Check your tracker settings or try again later."
        end
      end
    end
  end

  describe "DELETE /apps/:app_id/errs/:id/clear_issue" do
    before(:each) do
      sign_in Factory(:admin)
    end

    context "err with issue" do
      let(:err) { Factory :err, :issue_link => "http://some.host" }

      before(:each) do
        delete :clear_issue, :app_id => err.app.id, :id => err.id
        err.reload
      end

      it "should redirect to err page" do
        response.should redirect_to( app_err_path(err.app, err) )
      end

      it "should clear issue link" do
        err.issue_link.should be_nil
      end
    end

    context "err without issue" do
      let(:err) { Factory :err }

      before(:each) do
        delete :clear_issue, :app_id => err.app.id, :id => err.id
        err.reload
      end

      it "should redirect to err page" do
        response.should redirect_to( app_err_path(err.app, err) )
      end
    end
  end
end
