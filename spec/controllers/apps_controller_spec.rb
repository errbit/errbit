require 'spec_helper'

describe AppsController do

  it_requires_authentication
  it_requires_admin_privileges :for => {:new => :get, :edit => :get, :create => :post, :update => :put, :destroy => :delete}

  let(:admin) { Fabricate(:admin) }
  let(:user) { Fabricate(:user) }
  let(:watcher) { Fabricate(:user_watcher, :app => app, :user => user) }
  let(:unwatched_app) { Fabricate(:app) }
  let(:app) { unwatched_app }
  let(:watched_app1) do
    a = Fabricate(:app)
    Fabricate(:user_watcher, :user => user, :app => a)
    a
  end
  let(:watched_app2) do
    a = Fabricate(:app)
    Fabricate(:user_watcher, :user => user, :app => a)
    a
  end
  let(:err) do
    Fabricate(:err, :problem => problem)
  end
  let(:notice) do
    Fabricate(:notice, :err => err)
  end
  let(:problem) do
    Fabricate(:problem, :app => app)
  end
  let(:problem_resolved) { Fabricate(:problem_resolved, :app => app) }

  describe "GET /apps" do
    context 'when logged in as an admin' do
      it 'finds all apps' do
        sign_in admin
        unwatched_app && watched_app1 && watched_app2
        get :index
        expect(controller.apps.entries).to eq App.all.sort.entries
      end
    end

    context 'when logged in as a regular user' do
      it 'finds apps the user is watching' do
        sign_in(user)
        watched_app1 && watched_app2 && unwatched_app
        get :index
        expect(controller.apps).to include(watched_app1, watched_app2)
        expect(controller.apps).to_not include(unwatched_app)
      end
    end
  end

  describe "GET /apps/:id" do
    context 'logged in as an admin' do
      before(:each) do
        sign_in admin
      end

      it 'finds the app' do
        get :show, :id => app.id
        expect(controller.app).to eq app
      end

      it "should not raise errors for app with err without notices" do
        err
        expect{ get :show, :id => app.id }.to_not raise_error
      end

      it "should list atom feed successfully" do
        get :show, :id => app.id, :format => "atom"
        expect(response).to be_success
      end

      it "should list available watchers by name" do
        Fabricate(:user, :name => "Carol")
        Fabricate(:user, :name => "Alice")
        Fabricate(:user, :name => "Betty")

        get :show, :id => app.id

        expect(controller.users.to_a).to eq(User.all.to_a.sort_by(&:name))
      end

      context "pagination" do
        before(:each) do
          35.times { Fabricate(:err, :problem => Fabricate(:problem, :app => app)) }
        end

        it "should have default per_page value for user" do
          get :show, :id => app.id
          expect(controller.problems.to_a.size).to eq User::PER_PAGE
        end

        it "should be able to override default per_page value" do
          admin.update_attribute :per_page, 10
          get :show, :id => app.id
          expect(controller.problems.to_a.size).to eq 10
        end
      end

      context 'with resolved errors' do
        before(:each) do
          problem_resolved && problem
        end

        context 'and no params' do
          it 'shows only unresolved problems' do
            get :show, :id => app.id
            expect(controller.problems.size).to eq 1
          end
        end

        context 'and all_problems=true params' do
          it 'shows all errors' do
            get :show, :id => app.id, :all_errs => true
            expect(controller.problems.size).to eq 2
          end
        end
      end

      context 'with environment filters' do
        before(:each) do
          environments = ['production', 'test', 'development', 'staging']
          20.times do |i|
            Fabricate(:problem, :app => app, :environment => environments[i % environments.length])
          end
        end

        context 'no params' do
          it 'shows errs for all environments' do
            get :show, :id => app.id
            expect(controller.problems.size).to eq 20
          end
        end

        context 'environment production' do
          it 'shows errs for just production' do
            get :show, :id => app.id, :environment => 'production'
            expect(controller.problems.size).to eq 5
          end
        end

        context 'environment staging' do
          it 'shows errs for just staging' do
            get :show, :id => app.id, :environment => 'staging'
            expect(controller.problems.size).to eq 5
          end
        end

        context 'environment development' do
          it 'shows errs for just development' do
            get :show, :id => app.id, :environment => 'development'
            expect(controller.problems.size).to eq 5
          end
        end

        context 'environment test' do
          it 'shows errs for just test' do
            get :show, :id => app.id, :environment => 'test'
            expect(controller.problems.size).to eq 5
          end
        end
      end
    end

    context 'logged in as a user' do
      it 'finds the app if the user is watching it' do
        watcher
        sign_in user
        get :show, :id => app.id
        expect(controller.app).to eq app
      end

      it 'does not find the app if the user is not watching it' do
        sign_in Fabricate(:user)
        app = Fabricate(:app)
        expect{
          get :show, :id => app.id
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end
  end

  context 'logged in as an admin' do
    before do
      sign_in admin
    end

    describe "GET /apps/new" do
      it 'instantiates a new app with a prebuilt watcher' do
        get :new
        expect(controller.app).to be_a(App)
        expect(controller.app).to be_new_record
        expect(controller.app.watchers).to_not be_empty
      end

      it "should copy attributes from an existing app" do
        @app = Fabricate(:app, :name => "do not copy",
                             :github_repo => "test/example")
        get :new, :copy_attributes_from => @app.id
        expect(controller.app).to be_a(App)
        expect(controller.app).to be_new_record
        expect(controller.app.name).to be_blank
        expect(controller.app.github_repo).to eq "test/example"
      end
    end

    describe "GET /apps/:id/edit" do
      it 'finds the correct app' do
        app = Fabricate(:app)
        get :edit, :id => app.id
        expect(controller.app).to eq app
      end
    end

    describe "POST /apps" do
      before do
        @app = Fabricate(:app)
        App.stub(:new).and_return(@app)
      end

      context "when the create is successful" do
        before do
          expect(@app).to receive(:save).and_return(true)
        end

        it "should redirect to the app page" do
          post :create, :app => {}
          expect(response).to redirect_to(app_path(@app))
        end

        it "should display a message" do
          post :create, :app => {}
          expect(request.flash[:success]).to match(/success/)
        end
      end
    end

    describe "PUT /apps/:id" do
      before do
        @app = Fabricate(:app)
      end

      context "when the update is successful" do
        it "should redirect to the app page" do
          put :update, :id => @app.id, :app => {}
          expect(response).to redirect_to(app_path(@app))
        end

        it "should display a message" do
          put :update, :id => @app.id, :app => {}
          expect(request.flash[:success]).to match(/success/)
        end
      end

      context "changing name" do
        it "should redirect to app page" do
          id = @app.id
          put :update, :id => id, :app => {:name => "new name"}
          expect(response).to redirect_to(app_path(id))
        end
      end

      context "when the update is unsuccessful" do
        it "should render the edit page" do
          put :update, :id => @app.id, :app => { :name => '' }
          expect(response).to render_template(:edit)
        end
      end

      context "changing email_at_notices" do
        before do
          Errbit::Config.per_app_email_at_notices = true
        end

        it "should parse legal csv values" do
          put :update, :id => @app.id, :app => { :email_at_notices => '1,   4,      7,8,  10' }
          @app.reload
          expect(@app.email_at_notices).to eq [1, 4, 7, 8, 10]
        end
        context "failed parsing of CSV" do
          it "should set the default value" do
            @app = Fabricate(:app, :email_at_notices => [1, 2, 3, 4])
            put :update, :id => @app.id, :app => { :email_at_notices => 'asdf, -1,0,foobar,gd00,0,abc' }
            @app.reload
            expect(@app.email_at_notices).to eq Errbit::Config.email_at_notices
          end

          it "should display a message" do
            put :update, :id => @app.id, :app => { :email_at_notices => 'qwertyuiop' }
            expect(request.flash[:error]).to match(/Couldn't parse/)
          end
        end
      end

      context "setting up issue tracker", :cur => true do
        context "unknown tracker type" do
          before(:each) do
            put :update, :id => @app.id, :app => { :issue_tracker_attributes => {
              :type => 'unknown', :project_id => '1234', :api_token => '123123', :account => 'myapp'
            } }
            @app.reload
          end

          it "should not create issue tracker" do
            expect(@app.issue_tracker_configured?).to eq false
          end
        end

        IssueTracker.subclasses.each do |tracker_klass|
          context tracker_klass do
            it "should save tracker params" do
              params = tracker_klass::Fields.inject({}){|hash,f| hash[f[0]] = "test_value"; hash }
              params[:ticket_properties] = "card_type = defect" if tracker_klass == MingleTracker
              params[:type] = tracker_klass.to_s
              put :update, :id => @app.id, :app => {:issue_tracker_attributes => params}

              @app.reload

              tracker = @app.issue_tracker
              expect(tracker).to be_a(tracker_klass)
              tracker_klass::Fields.each do |field, field_info|
                case field
                when :ticket_properties
                  expect(tracker.send(field.to_sym)).to eq 'card_type = defect'
                else
                  expect(tracker.send(field.to_sym)).to eq 'test_value'
                end
              end
            end

            it "should show validation notice when sufficient params are not present" do
              # Leave out one required param
              params = tracker_klass::Fields[1..-1].inject({}){|hash,f| hash[f[0]] = "test_value"; hash }
              params[:type] = tracker_klass.to_s
              put :update, :id => @app.id, :app => {:issue_tracker_attributes => params}

              @app.reload
              expect(@app.issue_tracker_configured?).to eq false
            end
          end
        end
      end
    end

    describe "DELETE /apps/:id" do
      before do
        @app = Fabricate(:app)
      end

      it "should find the app" do
        delete :destroy, :id => @app.id
        expect(controller.app).to eq @app
      end

      it "should destroy the app" do
        expect(@app).to receive(:destroy)
        delete :destroy, :id => @app.id
      end

      it "should display a message" do
        delete :destroy, :id => @app.id
        expect(request.flash[:success]).to match(/success/)
      end

      it "should redirect to the apps page" do
        delete :destroy, :id => @app.id
        expect(response).to redirect_to(apps_path)
      end
    end
  end

  describe "POST /apps/:id/regenerate_api_key" do

    context "like watcher" do
      before do
        sign_in watcher.user
      end

      it 'redirect to root with flash error' do
        post :regenerate_api_key, :id => 'foo'
        expect(request).to redirect_to root_path
      end

    end

    context "like admin" do
      before do
        sign_in admin
      end

      it 'redirect_to app view' do
        expect do
          post :regenerate_api_key, :id => app.id
          expect(request).to redirect_to edit_app_path(app)
        end.to change { app.api_key }
      end
    end

  end

end
