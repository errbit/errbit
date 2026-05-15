# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppsController, type: :controller do
  it_requires_authentication
  it_requires_admin_privileges for: {new: :get, edit: :get, create: :post, update: :patch, destroy: :delete}

  let(:app_params) { {name: "BestApp"} }
  let(:admin) { create(:errbit_user, admin: true) }
  let(:user) { create(:errbit_user) }
  let(:unwatched_app) { create(:errbit_app) }
  let(:app) { unwatched_app }
  let(:watcher) { create(:errbit_user_watcher, app: app, user: user) }

  describe "GET /apps" do
    context "when logged in as an admin" do
      it "finds all apps" do
        sign_in admin
        unwatched_app

        get :index

        expect(controller.send(:apps).map(&:object)).to eq(Errbit::App.all.to_a.sort)
      end
    end

    context "when logged in as a regular user" do
      it "finds all apps" do
        sign_in user
        unwatched_app

        get :index

        expect(controller.send(:apps).map(&:object)).to eq(Errbit::App.all.to_a.sort)
      end
    end
  end

  describe "GET /apps/:id" do
    context "when logged in as an admin" do
      before { sign_in admin }

      it "finds the app" do
        get :show, params: {id: app.id}

        expect(controller.send(:app)).to eq(app)
      end

      it "does not raise errors for an app with an err but no notices" do
        create(:errbit_err, problem: create(:errbit_problem, app: app))

        expect { get :show, params: {id: app.id} }.not_to raise_error
      end

      it "responds successfully for the atom feed" do
        get :show, params: {id: app.id, format: "atom"}

        expect(response).to be_successful
      end

      it "lists available watchers by name" do
        create(:errbit_user, name: "Carol")
        create(:errbit_user, name: "Alice")
        create(:errbit_user, name: "Betty")

        get :show, params: {id: app.id}

        expect(controller.send(:users).to_a).to eq(Errbit::User.all.to_a.sort_by { |u| u.name.downcase })
      end

      context "with default pagination" do
        before { 35.times { create(:errbit_err, problem: create(:errbit_problem, app: app)) } }

        it "uses the default per_page value" do
          get :show, params: {id: app.id}

          expect(controller.send(:problems).to_a.size).to eq(Errbit::User::PER_PAGE)
        end

        it "honors the user's per_page override" do
          admin.update!(per_page: 10)

          get :show, params: {id: app.id}

          expect(controller.send(:problems).to_a.size).to eq(10)
        end
      end

      context "with resolved errors" do
        let!(:resolved_problem) do
          p = create(:errbit_problem, app: app)
          p.resolve!
          p
        end
        let!(:open_problem) { create(:errbit_problem, app: app) }

        context "without all_errs param" do
          it "shows only unresolved problems" do
            get :show, params: {id: app.id}

            expect(controller.send(:problems).size).to eq(1)
          end
        end

        context "with all_errs=true" do
          it "shows all problems" do
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

        context "without any environment param" do
          it "shows problems for every environment" do
            get :show, params: {id: app.id}

            expect(controller.send(:problems).size).to eq(20)
          end
        end

        context "with environment=production" do
          it "filters to just production" do
            get :show, params: {id: app.id, environment: "production"}

            expect(controller.send(:problems).size).to eq(5)
          end
        end

        context "with environment=staging" do
          it "filters to just staging" do
            get :show, params: {id: app.id, environment: "staging"}

            expect(controller.send(:problems).size).to eq(5)
          end
        end
      end
    end

    context "when logged in as a regular user" do
      it "finds the app even when not watching it" do
        sign_in create(:errbit_user)
        the_app = create(:errbit_app)

        get :show, params: {id: the_app.id}

        expect(controller.send(:app)).to eq(the_app)
      end
    end
  end

  context "when signed in as an admin" do
    before { sign_in admin }

    describe "GET /apps/new" do
      it "instantiates a new app with a prebuilt watcher" do
        get :new

        expect(controller.send(:app)).to be_a(Errbit::App)
        expect(controller.send(:app)).to be_new_record
        expect(controller.send(:app).watchers).not_to be_empty
      end

      it "copies attributes from an existing app when copy_attributes_from is set" do
        @existing = create(:errbit_app, name: "do not copy", github_repo: "test/example")

        get :new, params: {copy_attributes_from: @existing.id}

        expect(controller.send(:app)).to be_a(Errbit::App)
        expect(controller.send(:app)).to be_new_record
        expect(controller.send(:app).name).to be_blank
        expect(controller.send(:app).github_repo).to eq("test/example")
      end
    end

    describe "GET /apps/:id/edit" do
      it "finds the correct app" do
        the_app = create(:errbit_app)

        get :edit, params: {id: the_app.id}

        expect(controller.send(:app)).to eq(the_app)
      end
    end

    describe "POST /apps" do
      context "with a successful create" do
        it "redirects to the app page" do
          post :create, params: {app: app_params}

          expect(response).to redirect_to(app_path(assigns(:app)))
        end

        it "flashes a success message" do
          post :create, params: {app: app_params}

          expect(request.flash[:success]).to match(/success/)
        end
      end
    end

    describe "PATCH /apps/:id" do
      let!(:the_app) { create(:errbit_app) }

      context "with a successful update" do
        it "redirects to the app page" do
          patch :update, params: {id: the_app.id, app: app_params}

          expect(response).to redirect_to(app_path(the_app))
        end

        it "flashes a success message" do
          patch :update, params: {id: the_app.id, app: app_params}

          expect(request.flash[:success]).to match(/success/)
        end
      end

      context "when changing the name" do
        it "redirects to the app page" do
          patch :update, params: {id: the_app.id, app: {name: "new name"}}

          expect(response).to redirect_to(app_path(the_app))
        end
      end

      context "with an unsuccessful update" do
        it "renders the edit page" do
          patch :update, params: {id: the_app.id, app: {name: ""}}

          expect(response).to render_template(:edit)
        end
      end

      context "when changing email_at_notices" do
        before { allow(Errbit::Config).to receive(:per_app_email_at_notices).and_return(true) }

        it "parses legal CSV values" do
          patch :update, params: {id: the_app.id, app: {email_at_notices: "1,   4,      7,8,  10"}}

          the_app.reload

          expect(the_app.email_at_notices).to eq([1, 4, 7, 8, 10])
        end

        context "when CSV parsing fails" do
          it "resets to the default value" do
            patch :update, params: {id: the_app.id, app: {email_at_notices: "asdf, -1,0,foobar,gd00,0,abc"}}

            the_app.reload

            expect(the_app.email_at_notices).to eq(Errbit::Config.email_at_notices)
          end

          it "flashes an error message" do
            patch :update, params: {id: the_app.id, app: {email_at_notices: "qwertyuiop"}}

            expect(request.flash[:error]).to match(/Couldn't parse/)
          end
        end
      end

      context "when setting up an issue tracker with an unknown type" do
        before do
          patch :update, params: {
            id: the_app.id,
            app: {
              issue_tracker_attributes: {
                type_tracker: "unknown",
                options: {project_id: "1234", api_token: "123123", account: "myapp"}
              }
            }
          }
          the_app.reload
        end

        it "does not create an issue tracker" do
          expect(the_app.issue_tracker_configured?).to eq(false)
        end
      end
    end

    describe "DELETE /apps/:id" do
      let!(:the_app) { create(:errbit_app) }

      it "finds the app" do
        delete :destroy, params: {id: the_app.id}

        expect(controller.send(:app)).to eq(the_app)
      end

      it "destroys the app" do
        delete :destroy, params: {id: the_app.id}

        expect { the_app.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "flashes a success message" do
        delete :destroy, params: {id: the_app.id}

        expect(request.flash[:success]).to match(/success/)
      end

      it "redirects to the apps page" do
        delete :destroy, params: {id: the_app.id}

        expect(response).to redirect_to(apps_path)
      end
    end
  end

  describe "POST /apps/:id/regenerate_api_key" do
    context "when called by a watcher (non-admin)" do
      before { sign_in watcher.user }

      it "redirects to root path" do
        post :regenerate_api_key, params: {id: app.id}

        expect(request).to redirect_to(root_path)
      end
    end

    context "when called by an admin" do
      before { sign_in admin }

      it "regenerates the api_key and redirects to the edit page" do
        expect {
          post :regenerate_api_key, params: {id: app.id}
        }.to change { app.reload.api_key }

        expect(request).to redirect_to(edit_app_path(app))
      end
    end
  end

  describe "GET /apps/search" do
    before do
      sign_in user
      @app_foo = create(:errbit_app, name: "Foo")
      @app_bar = create(:errbit_app, name: "Bar")
    end

    it "renders successfully" do
      get :search

      expect(response).to be_successful
    end

    it "renders the index template" do
      get :search

      expect(response).to render_template("apps/index")
    end

    it "filters apps by the search string" do
      get :search, params: {search: "Foo"}

      expect(controller.send(:apps).map(&:object)).to include(@app_foo)
      expect(controller.send(:apps).map(&:object)).not_to include(@app_bar)
    end

    it "returns every app when the search string is empty" do
      get :search, params: {search: ""}

      expect(controller.send(:apps).map(&:object)).to include(@app_foo, @app_bar)
    end
  end
end
