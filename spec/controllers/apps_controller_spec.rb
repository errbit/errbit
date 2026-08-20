# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppsController, type: :controller do
  it_requires_authentication
  it_requires_admin_privileges for: {new: :get, edit: :get, create: :post, update: :patch, destroy: :delete}

  let(:app_params) { {name: "BestApp"} }
  let(:admin) { create(:errbit_user, admin: true) }
  let(:user) { create(:errbit_user) }
  let(:watcher) { create(:errbit_watcher, app: app, user: user, email: nil, watcher_type: "user") }
  let(:unwatched_app) { create(:errbit_app) }
  let(:app) { unwatched_app }
  let(:watched_app_1) do
    a = create(:errbit_app)
    create(:errbit_watcher, user: user, app: a, email: nil, watcher_type: "user")
    a
  end
  let(:watched_app_2) do
    a = create(:errbit_app)
    create(:errbit_watcher, user: user, app: a, email: nil, watcher_type: "user")
    a
  end
  let(:err) do
    create(:errbit_err, problem: problem)
  end
  let(:notice) do
    create(:errbit_notice, err: err)
  end
  let(:problem) do
    create(:errbit_problem, app: app)
  end
  let(:problem_resolved) { create(:errbit_problem, app: app, resolved: true) }
  let(:notice_fingerprinter) do
    Errbit::SiteConfig.document.notice_fingerprinter_attributes.merge(backtrace_lines: 10)
  end

  describe "GET /apps" do
    context "when logged in as an admin" do
      it "finds all apps" do
        sign_in admin
        unwatched_app && watched_app_1 && watched_app_2
        get :index
        expect(controller.send(:apps).entries).to eq(Errbit::App.all.to_a.sort.entries)
      end
    end

    context "when logged in as a regular user" do
      it "finds all apps" do
        sign_in user
        unwatched_app && watched_app_1 && watched_app_2
        get :index
        expect(controller.send(:apps).entries).to eq(Errbit::App.all.to_a.sort.entries)
      end
    end
  end

  describe "GET /apps/:id" do
    context "logged in as an admin" do
      before do
        sign_in admin
      end

      it "finds the app" do
        get :show, params: {id: app.id}
        expect(controller.send(:app)).to eq(app)
      end

      it "should not raise errors for app with err without notices" do
        err
        expect { get :show, params: {id: app.id} }.not_to raise_error
      end

      it "should list atom feed successfully" do
        get :show, params: {id: app.id, format: "atom"}
        expect(response).to be_successful
      end

      it "should list available watchers by name" do
        create(:errbit_user, name: "Carol")
        create(:errbit_user, name: "Alice")
        create(:errbit_user, name: "Betty")

        get :show, params: {id: app.id}

        expect(controller.send(:users).to_a).to eq(Errbit::User.all.to_a.sort_by(&:name))
      end

      context "pagination" do
        before do
          35.times { create(:errbit_err, problem: create(:errbit_problem, app: app)) }
        end

        it "should have default per_page value for user" do
          get :show, params: {id: app.id}

          expect(controller.send(:problems).to_a.size).to eq(Errbit::User::PER_PAGE)
        end

        it "should be able to override default per_page value" do
          admin.update_attribute :per_page, 10

          get :show, params: {id: app.id}

          expect(controller.send(:problems).to_a.size).to eq(10)
        end
      end

      context "with resolved errors" do
        before do
          problem_resolved && problem
        end

        context "and no params" do
          it "shows only unresolved problems" do
            get :show, params: {id: app.id}
            expect(controller.send(:problems).size).to eq(1)
          end
        end

        context "and all_problems=true params" do
          it "shows all errors" do
            get :show, params: {id: app.id, all_errs: true}
            expect(controller.send(:problems).size).to eq(2)
          end
        end
      end

      context "with environment filters" do
        before do
          environments = ["production", "test", "development", "staging"]
          20.times do |i|
            create(:errbit_problem, app: app, environment: environments[i % environments.length])
          end
        end

        context "no params" do
          it "shows errs for all environments" do
            get :show, params: {id: app.id}

            expect(controller.send(:problems).size).to eq(20)
          end
        end

        context "environment production" do
          it "shows errs for just production" do
            get :show, params: {id: app.id, environment: "production"}

            expect(controller.send(:problems).size).to eq(5)
          end
        end

        context "environment staging" do
          it "shows errs for just staging" do
            get :show, params: {id: app.id, environment: "staging"}

            expect(controller.send(:problems).size).to eq(5)
          end
        end

        context "environment development" do
          it "shows errs for just development" do
            get :show, params: {id: app.id, environment: "development"}

            expect(controller.send(:problems).size).to eq(5)
          end
        end

        context "environment test" do
          it "shows errs for just test" do
            get :show, params: {id: app.id, environment: "test"}

            expect(controller.send(:problems).size).to eq(5)
          end
        end
      end
    end

    context "logged in as a user" do
      it "finds the app even when not watching it" do
        sign_in create(:errbit_user)

        app = create(:errbit_app)

        get :show, params: {id: app.id}

        expect(controller.send(:app)).to eq(app)
      end
    end
  end

  context "logged in as an admin" do
    before do
      sign_in admin
    end

    describe "GET /apps/new" do
      it "instantiates a new app with a prebuilt watcher" do
        get :new
        expect(controller.send(:app)).to be_a(Errbit::App)
        expect(controller.send(:app)).to be_new_record
        expect(controller.send(:app).watchers).not_to be_empty
      end

      it "should copy attributes from an existing app" do
        @app = create(:errbit_app, name: "do not copy", github_repo: "test/example")
        get :new, params: {copy_attributes_from: @app.id}
        expect(controller.send(:app)).to be_a(Errbit::App)
        expect(controller.send(:app)).to be_new_record
        expect(controller.send(:app).name).to be_blank
        expect(controller.send(:app).github_repo).to eq("test/example")
      end
    end

    describe "GET /apps/:id/edit" do
      it "finds the correct app" do
        app = create(:errbit_app)

        get :edit, params: {id: app.id}

        expect(controller.send(:app)).to eq(app)
      end
    end

    describe "POST /apps" do
      before do
        @app = create(:errbit_app)

        allow(Errbit::App).to receive(:new).and_return(@app)
      end

      context "when the create is successful" do
        before do
          expect(@app).to receive(:save).and_return(true)
        end

        it "should redirect to the app page" do
          post :create, params: {app: app_params}
          expect(response).to redirect_to(app_path(@app))
        end

        it "should display a message" do
          post :create, params: {app: app_params}
          expect(request.flash[:success]).to match(/success/)
        end
      end
    end

    describe "PATCH /apps/:id" do
      before do
        @app = create(:errbit_app)
      end

      context "when the update is successful" do
        it "should redirect to the app page" do
          patch :update, params: {id: @app.id, app: app_params}
          expect(response).to redirect_to(app_path(@app))
        end

        it "should display a message" do
          patch :update, params: {id: @app.id, app: app_params}
          expect(request.flash[:success]).to match(/success/)
        end
      end

      context "changing name" do
        it "should redirect to app page" do
          id = @app.id
          patch :update, params: {id: id, app: {name: "new name"}}
          expect(response).to redirect_to(app_path(id))
        end
      end

      context "when the update is unsuccessful" do
        it "should render the edit page" do
          patch :update, params: {id: @app.id, app: {name: ""}}
          expect(response).to render_template(:edit)
        end
      end

      context "changing email_at_notices" do
        before do
          allow(Errbit::Config)
            .to receive(:per_app_email_at_notices).and_return(true)
        end

        it "should parse legal csv values" do
          patch :update, params: {id: @app.id, app: {email_at_notices: "1,   4,      7,8,  10"}}

          @app.reload

          expect(@app.email_at_notices).to eq([1, 4, 7, 8, 10])
        end

        context "failed parsing of CSV" do
          it "should set the default value" do
            @app = create(:errbit_app, email_at_notices: [1, 2, 3, 4])

            patch :update, params: {id: @app.id, app: {email_at_notices: "asdf, -1,0,foobar,gd00,0,abc"}}

            @app.reload

            expect(@app.email_at_notices).to eq(Errbit::Config.email_at_notices)
          end

          it "should display a message" do
            patch :update, params: {id: @app.id, app: {email_at_notices: "qwertyuiop"}}

            expect(request.flash[:error]).to match(/Couldn't parse/)
          end
        end
      end

      context "setting up issue tracker" do
        context "unknown tracker type" do
          before do
            patch :update, params: {
              id: @app.id,
              app: {
                issue_tracker_attributes: {
                  type_tracker: "unknown",
                  options: {
                    project_id: "1234",
                    api_token: "123123",
                    account: "myapp"
                  }
                }
              }
            }

            @app.reload
          end

          it "should not create issue tracker" do
            expect(@app.issue_tracker_configured?).to eq(false)
          end
        end
      end

      context "selecting 'use site fingerprinter'" do
        before do
          Errbit::SiteConfig.document.update!(notice_fingerprinter_attributes: notice_fingerprinter)

          patch :update, params: {
            id: @app.id,
            app: {
              notice_fingerprinter_attributes: {
                backtrace_lines: 42
              },
              use_site_fingerprinter: "1"
            }
          }
        end

        it "should copy site fingerprinter into app fingerprinter" do
          fingerprinter_attrs = @app.reload.notice_fingerprinter.attributes.slice(*Errbit::SiteConfig::NOTICE_FINGERPRINTER_FIELDS.map(&:to_s))
          expected_attrs = Errbit::SiteConfig.document.attributes.slice(*Errbit::SiteConfig::NOTICE_FINGERPRINTER_FIELDS.map(&:to_s))
          expect(fingerprinter_attrs).to eq(expected_attrs)
        end
      end

      context "not selecting 'use site fingerprinter'" do
        before do
          Errbit::SiteConfig.document.update!(notice_fingerprinter_attributes: notice_fingerprinter)

          patch :update, params: {
            id: @app.id,
            app: {
              notice_fingerprinter_attributes: {
                backtrace_lines: 42
              },
              use_site_fingerprinter: "0"
            }
          }
        end

        it "shouldn't copy site fingerprinter into app fingerprinter" do
          fingerprinter_attrs = @app.reload.notice_fingerprinter.attributes.slice(*Errbit::SiteConfig::NOTICE_FINGERPRINTER_FIELDS.map(&:to_s))
          expected_attrs = Errbit::SiteConfig.document.attributes.slice(*Errbit::SiteConfig::NOTICE_FINGERPRINTER_FIELDS.map(&:to_s))
          expect(fingerprinter_attrs).not_to eq(expected_attrs)
          expect(@app.notice_fingerprinter.backtrace_lines).to eq(42)
        end
      end
    end

    describe "DELETE /apps/:id" do
      before do
        @app = create(:errbit_app)
      end

      it "should find the app" do
        delete :destroy, params: {id: @app.id}
        expect(controller.send(:app)).to eq(@app)
      end

      it "should destroy the app" do
        delete :destroy, params: {id: @app.id}
        expect do
          @app.reload
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "should display a message" do
        delete :destroy, params: {id: @app.id}

        expect(request.flash[:success]).to match(/success/)
      end

      it "should redirect to the apps page" do
        delete :destroy, params: {id: @app.id}

        expect(response).to redirect_to(apps_path)
      end
    end
  end

  describe "POST /apps/:id/regenerate_api_key" do
    context "like watcher" do
      before do
        sign_in watcher.user
      end

      it "redirect to root with flash error" do
        post :regenerate_api_key, params: {id: "foo"}

        expect(request).to redirect_to(root_path)
      end
    end

    context "like admin" do
      before do
        sign_in admin
      end

      it "redirect_to app view" do
        expect do
          post :regenerate_api_key, params: {id: app.id}
          expect(request).to redirect_to edit_app_path(app)
        end.to change { app.reload.api_key }
      end
    end
  end

  describe "GET /apps/search" do
    before do
      sign_in user
      @app_1 = create(:errbit_app, name: "Foo")
      @app_2 = create(:errbit_app, name: "Bar")
    end

    it "renders successfully" do
      get :search

      expect(response).to be_successful
    end

    it "renders index template" do
      get :search

      expect(response).to render_template("apps/index")
    end

    it "searches problems for given string" do
      get :search, params: {search: "Foo"}

      expect(controller.send(:apps)).to include(@app_1)
      expect(controller.send(:apps)).not_to include(@app_2)
    end

    it "works when given string is empty" do
      get :search, params: {search: ""}

      expect(controller.send(:apps)).to include(@app_1)
      expect(controller.send(:apps)).to include(@app_2)
    end
  end
end
